"""Testing script for rubble with chain-replication

This is the rubble setup script for rubble with chain-replication. It will read the
configuration parameters from test_config.yml, and then do the following 
things:
1. Setup the SST files transmission path according to the chain configuration,
   for example, for each pair in chain-replication, it will set the NVMe device 
   on the next node to as the NVMe device target on the previous node via 
   NVMe-oF-RDMA if that is the network protocol configured by user
2. Install our modified rubble-version of RocksDB and rubble clients on every 
   nodes in the chain.
4. Install the replicator.

  Typical usage example:

  python test_full.py
"""

import yaml
from pprint import pformat
import logging
import os
import yamale
import subprocess
import threading
import time
import paramiko
import argparse
import sys
import config
import configparser

from utils.config import read_config, check_config
from utils.utils import print_success, print_error, print_script_stdout, print_script_stderr
from ssh_utils.ssh_utils import run_script_helper, \
  run_script_on_local_machine, run_script_on_remote_machine, \
    run_script_on_remote_machine_background, init_ssh_clients, \
      close_ssh_clients, run_command_on_remote_machine, \
        transmit_file_to_remote_machine

config.CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

logging.basicConfig(level=logging.INFO)

physical_env_params=dict()
request_params=dict()
rubble_params=dict()
operator_ip = ''


def setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict):
  # We setup NVMe-oF through RDMA on every neighbor server pairs in chain.
  server_ips = list(physical_env_params['server_info'].keys())
  block_devices = [ server['block_device']['device_path'] for server in physical_env_params['server_info'].values() ]
  server_ips_pairs = [[server_ips[i], server_ips[i+1], block_devices[i+1]] for i in range(len(server_ips)-1)]
  server_ips_pairs.append(list((server_ips[len(server_ips)-1], server_ips[0], block_devices[0])))
  print("[**********block device*************]", block_devices[0])
  NVMe_oF_RDMA_script_path = config.CURRENT_PATH.rsplit('/', 1)[0]+'/setup_scripts/NVME_over_Fabrics'
  for ip_pairs in server_ips_pairs:
    client_ip = ip_pairs[0]
    target_ip = ip_pairs[1]
    target_device = ip_pairs[2]
    nvme_of_namespace = physical_env_params['server_info'][target_ip]['block_device']['nvme_of_namespace']
    logging.info('Setting up NVMe-oF for {}'.format(ip_pairs))
    logging.info('Client IP: {}'.format(client_ip))
    logging.info('Target IP: {}'.format(target_ip))
    logging.info('Target Device: {}'.format(target_device))
    logging.info('Target NVMe Subsystem namespace: {}'.format(nvme_of_namespace))
    logging.info('NVMe-oF-RDMA script path: {}'.format(NVMe_oF_RDMA_script_path))
    if (target_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        NVMe_oF_RDMA_script_path+'/target_setup.sh',
        params='--target-ip-address={} --subsystem-name={} --device-path={}'.format(
          target_ip, nvme_of_namespace, target_device)
      )
    else:
      run_script_on_remote_machine(
        target_ip,
        NVMe_oF_RDMA_script_path+'/target_setup.sh',
        ssh_client_dict,
        params='--target-ip-address={} --subsystem-name={} --device-path={}'.format(
          target_ip, nvme_of_namespace, target_device)
      )
    if (client_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        NVMe_oF_RDMA_script_path+'/client_setup.sh', 
        params='--is-connect=true --target-ip-address={} --subsystem-name={}'.format(target_ip, nvme_of_namespace)
      )  
    else:
      run_script_on_remote_machine(
        client_ip, 
        NVMe_oF_RDMA_script_path+'/client_setup.sh', 
        ssh_client_dict,
        params='--is-connect=true --target-ip-address={} --subsystem-name={}'.format(target_ip, nvme_of_namespace)
      )


def setup_NVMe_oF_TCP(physical_env_params, ssh_client_dict):
  logging.warning("NVMe-oF through TCP setup has not been implemented")
  exit(1)


def setup_NVMe_oF_i10(physical_env_params, ssh_client_dict):
  logging.warning("i10 needs manual setup since it relies on a specific version of Linux kernel")
  exit(1)


def install_rocksdbs(physical_env_params, ssh_client_dict):
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  gRPC_path = config.CURRENT_PATH.rsplit('/', 1)[0]+'/setup_scripts/gRPC'
  threads = []
  for server_ip in server_ips:
    logging.info("Installing RocksDB on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      t = threading.Thread(target=run_script_on_local_machine,
                           args=(rubble_script_path+'/rocksdb_setup.sh',
                                '--rubble-branch=rubble --rubble-path={}'.format(
                                  physical_env_params['server_info'][server_ip]['work_path']),
                                  [gRPC_path+'/cmake_install.sh',
                                   gRPC_path+'/grpc_setup.sh']))
      threads.append(t)
      t.start()
    else:
      t = threading.Thread(target=run_script_on_remote_machine,
                           args=(server_ip,
                                 rubble_script_path+'/rocksdb_setup.sh',
                                 ssh_client_dict,
                                 '--rubble-branch=rubble --rubble-path={}'.format(
                                   physical_env_params['server_info'][server_ip]['work_path']),
                                 [ gRPC_path+'/cmake_install.sh',
                                   gRPC_path+'/grpc_setup.sh'] )
                            )
      threads.append(t)
      t.start()
  for t in threads:
    t.join()


def install_ycsb(physical_env_params, ssh_client_dict):
  head_ip = physical_env_params['operator_ip']
  if head_ip == physical_env_params['operator_ip']:
    run_script_on_local_machine(
      config.CURRENT_PATH+'/rubble_ycsb/ycsb_setup.sh',
      params='--ycsb-branch={} --work-path={}'.format(
        physical_env_params['ycsb']['replicator']['branch'],
        physical_env_params['operator_work_path']
      )
    )
  else:
    run_script_on_remote_machine(
      head_ip,
      config.CURRENT_PATH+'/rubble_ycsb/ycsb_setup.sh',
      ssh_client_dict,
      params='--ycsb-branch={} --work-path={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['operator_work_path']
      )
    )

def install_rubble_clients(physical_env_params, ssh_client_dict):
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  for server_ip in server_ips:
    logging.info("Installing rubble client on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        rubble_script_path+'/rubble_client_setup.sh',
        params='--rubble-branch=rubble --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path'])
      )
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_path+'/rubble_client_setup.sh',
        ssh_client_dict,
        params='--rubble-branch=rubble --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path']),
      )

def setup_m510(physical_env_params, ssh_client_dict):
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = config.CURRENT_PATH.rsplit('/', 1)[0]+'/setup_scripts/setup_single_env.sh'
  for server_ip in server_ips:
    logging.info("Initial m510 setup on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      continue
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_path,
        ssh_client_dict,
      )

def preallocate_slots(physical_env_params, rubble_params, ssh_client_dict, ip_map):
  rubble_branch = physical_env_params['rocksdb']['branch']
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb/rubble_client_run.sh'
  threads = []
  port = "" 
  for shard in rubble_params['shard_info']:
    logging.info("Bring up tail client on chain {} to pre-allocate slots".format(shard['tag']))
    ip = shard['sequence'][-1]['ip']
    # port = ip_map[rubble_params['replicator_ip']] + ":" + str(rubble_params['replicator_port'])
    # no need to fill in real target addr here, only allocating slots
    work_path = physical_env_params['server_info'][ip]['work_path']
    t = threading.Thread(target=run_script_helper,
                         args=(ip, rubble_script_path, ssh_client_dict,
                         '--rubble-branch={} --rubble-path={} --rubble-mode={} --next-port={}'.format(
                            rubble_branch,
                            work_path+'/my_rocksdb/rubble',
                            'tail',
                            port
                          ),[]))
    threads.append(t)
    t.start()
  for t in threads:
    t.join()
  # sleep for 30 seconds until all slots are allocated
  time.sleep(30)
  
  
def setup_physical_env(physical_env_params, rubble_params, ssh_client_dict, ip_map, is_m510=False):
  if is_m510:
    # Run cloudlab specific init scripts.
    setup_m510(physical_env_params, ssh_client_dict)

  # Install RocksDB on every nodes. // from here can be parallized
  install_rocksdbs(physical_env_params, ssh_client_dict)
  
  # Install rubble clients on every nodes.
  install_rubble_clients(physical_env_params, ssh_client_dict)

  preallocate_slots(physical_env_params, rubble_params, ssh_client_dict, ip_map)

  # Conigure SST file shipping path.
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict)
  elif physical_env_params['network_protocol'] == 'NVMe-oF-TCP':
    setup_NVMe_oF_i10(physical_env_params, ssh_client_dict)

  # Install YCSB on the head node.
  install_ycsb(physical_env_params, ssh_client_dict)


def rubble_cleanup(physical_env_params,ssh_client_dict):
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  server_ips = list(physical_env_params['server_info'].keys())
  for server_ip in server_ips:
    logging.info("rubble cleanup on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        rubble_script_path+'/rubble_cleanup.sh',
      )
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_path+'/rubble_cleanup.sh',
        ssh_client_dict,
      )

def run_rocksdb_servers(physical_env_params, rubble_params, ssh_client_dict, ip_map, is_rubble='true'):

  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  
  # Cleanup before each run
  rubble_cleanup(physical_env_params, ssh_client_dict)
    
  # Bring up all RocksDB Clients
  for shard in rubble_params['shard_info']:
    logging.info("Bringing up chain {}".format(shard['tag']))
    chain_len = len(shard['sequence'])
    rocksdb_config = configparser.ConfigParser()
    rocksdb_config.read('rubble_rocksdb/rocksdb_config_file.ini')
    for i in range(chain_len-1, -1, -1):
      ip = shard['sequence'][i]['ip']
      logging.info("Bring up rubble client on {}...".format(ip))
      port = ip + ":" + str(shard['sequence'][i]['port'])
      mode = 'vanilla'
      rubble_branch = physical_env_params['rocksdb']['branch']
      work_path = physical_env_params['server_info'][ip]['work_path']
      if chain_len == 1:
        mode = 'vanilla'
        port = ip_map[rubble_params['replicator_ip']] + ":" + str(rubble_params['replicator_port'])
        rocksdb_config['DBOptions']['is_rubble'] = is_rubble
      elif i == 0:
        # Setup head node
        mode = 'primary'
        port = ip_map[shard['sequence'][i+1]['ip']] + ":" + str(shard['sequence'][i+1]['port'])
        rocksdb_config['DBOptions']['is_rubble'] = is_rubble
      elif i == chain_len-1:
        # Setup tail node
        mode = 'tail'
        port = ip_map[rubble_params['replicator_ip']] + ":" + str(rubble_params['replicator_port'])
        # TODO: this needs to be in test_config as well
        rocksdb_config['DBOptions']['is_rubble'] = is_rubble
      else:
        # Setup regular node
        mode = 'secondary'
        port = ip_map[shard['sequence'][i+1]['ip']] + ":" + str(shard['sequence'][i+1]['port'])
        rocksdb_config['DBOptions']['is_rubble'] = is_rubble
      with open('/tmp/rubble_scripts/rocksdb_config_file.ini', 'w') as configfile:
        rocksdb_config.write(configfile)
      if ip == rubble_params['replicator_ip']:
        process = subprocess.Popen(
          'cp /tmp/rubble_scripts/rocksdb_config_file.ini {}/my_rocksdb/rubble/'.format(
            work_path
          ), 
          shell=True, stdout=sys.stdout, stderr=sys.stderr
        )
        process.wait()
      else:
        transmit_file_to_remote_machine(
          ip, '/tmp/rubble_scripts/rocksdb_config_file.ini',
          '{}/my_rocksdb/rubble/rocksdb_config_file.ini'.format(
            work_path
          ),
          ssh_client_dict
        )
      run_script_helper(
        ip,
        rubble_script_path+'/rubble_client_run.sh',
        ssh_client_dict,
        params='--rubble-branch={} --rubble-path={} --rubble-mode={} --next-port={}'.format(
          rubble_branch,
          work_path+'/my_rocksdb/rubble',
          mode,
          port
        ),
        additional_scripts_paths=[]
      )

def run_replicator(physical_env_params, ssh_client_dict):
  ycsb_script_path = config.CURRENT_PATH+'/rubble_ycsb'
  # Generate the replicator configuration file and copy it to the directory of replicator.
  # For simplicity, we will just copy the entire test_config.yml to replicator directory now.
  # TODO: note that we also assume that replicator is always on the operator node
  process = subprocess.Popen(
    'cp {}/test_config.yml {}/YCSB/replicator/test.yml'.format(
      config.CURRENT_PATH, physical_env_params['operator_work_path']
    ), 
    shell=True, stdout=sys.stdout, stderr=sys.stderr
  )
  process.wait()

  # Bring up Replicator and run test
  run_script_helper(
    ip=physical_env_params['operator_ip'],
    script_path=ycsb_script_path+'/replicator_setup.sh',
    ssh_client_dict=ssh_client_dict,
    params='--ycsb-branch={} --rubble-path={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['operator_work_path'],
    ),
  )  

# TODO: replicator_ip
def base_ycsb(physical_env_params, rubble_params, ssh_client_dict, ip_map, op='run'):
  ycsb_script_path = config.CURRENT_PATH+'/rubble_ycsb'
  print("IP MAP: ", ip_map)
  print("rubble param ip: ", rubble_params['replicator_ip'])
  # ycsb operation
  run_script_helper(
    ip=physical_env_params['operator_ip'],
    script_path=ycsb_script_path+'/ycsb_run.sh',
    ssh_client_dict=ssh_client_dict,
    params='--ycsb-branch={} --rubble-path={} --ycsb-mode={} --thread-num={} --replicator-addr={} --replicator-batch-size={} --workload={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['operator_work_path'],
      op,
      rubble_params['chan_num'],
      ip_map[rubble_params['replicator_ip']]+':'+str(rubble_params['replicator_port']), #replicator-addr
      rubble_params['batch_size'], #replicator-batch-size
      rubble_params['ycsb_workload'], #workload
    ),
    additional_scripts_paths=[],
  )


# TODO: parameterize the remote sst dir as well
# TODO: parameterize is_rubble flag in test_config.yml file
def test_script(physical_env_params, rubble_params, ssh_client_dict, ip_map):
  run_rocksdb_servers(physical_env_params, rubble_params, ssh_client_dict, ip_map, 'false')
  # run_replicator(physical_env_params, ssh_client_dict)
  # base_ycsb(physical_env_params, rubble_params, ssh_client_dict, ip_map, 'load')
  # base_ycsb(physical_env_params, rubble_params, ssh_client_dict, ip_map,'run')
  

def main():
  parser = argparse.ArgumentParser(
    description='Process arguments for rubble_init.py'
  )
  parser.add_argument(
    '--dryrun',
    help='''
    Perform the dryrun, only confirm if the configuration 
    works without actually run the tasks.
    ''',
    action="store_true"
  )
  parser.add_argument(
    '--setup',
    help='Set up the experiment environment for test, run once before running with --test flag',
    action="store_true"
  )
  parser.add_argument(
    '--test',
    help='Run test function of rubble_init.py, this is for developing the script',
    action="store_true"
  )

  args = parser.parse_args()
  if args.dryrun:
    config_dict = dict()
    read_config(config_dict)
    logging.info("test configs: "+pformat(config_dict))
    check_config(config_dict)
    ssh_client_dict = init_ssh_clients(config_dict['physical_env_params'])
    ip_map = config_dict['ip_map']
    close_ssh_clients(ssh_client_dict)
    exit(1)

  config_dict = dict()
  read_config(config_dict)
  logging.info("test configs: "+pformat(config_dict))
  check_config(config_dict)
  physical_env_params = config_dict['physical_env_params']
  request_params = config_dict['request_params']
  rubble_params = config_dict['rubble_params']
  ip_map = config_dict['ip_map']
  config.OPERATOR_IP=physical_env_params['operator_ip']
  ssh_client_dict = init_ssh_clients(physical_env_params)

  # TODO: whether or not to run is_rubble should be listed in test_config.yml
  if args.setup:
    setup_physical_env(physical_env_params, rubble_params, ssh_client_dict, ip_map, True)

  if args.test:
    test_script(physical_env_params, rubble_params, ssh_client_dict, ip_map)
    # close_ssh_clients(ssh_client_dict)
    # exit(1)
  
  close_ssh_clients(ssh_client_dict)


if __name__ == '__main__':
  main()
