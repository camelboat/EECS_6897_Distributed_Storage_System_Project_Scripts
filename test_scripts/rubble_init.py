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
  server_ips_pairs.append(list(server_ips[len(server_ips)-1], server_ips[0]))
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
  for server_ip in server_ips:
    logging.info("Installing RocksDB on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        rubble_script_path+'/rocksdb_setup.sh',
        params='--rubble-branch=rubble --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path']),
        additional_scripts_paths=[
          gRPC_path+'/cmake_install.sh',
          gRPC_path+'/grpc_setup.sh'
        ]
      )
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_path+'/rocksdb_setup.sh',
        ssh_client_dict,
        params='--rubble-branch=rubble --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path']),
        additional_scripts_paths=[
          gRPC_path+'/cmake_install.sh',
          gRPC_path+'/grpc_setup.sh'
        ] 
      )


def install_ycsb(physical_env_params, ssh_client_dict):
  # head_ip = list(physical_env_params['server_info'].keys())[0]
  head_ip = physical_env_params['operator_ip']
  if head_ip == physical_env_params['operator_ip']:
    run_script_on_local_machine(
      config.CURRENT_PATH+'/rubble_ycsb/ycsb_setup.sh'
    )
  else:
    run_script_on_remote_machine(
      head_ip,
      config.CURRENT_PATH+'/rubble_ycsb/ycsb_setup.sh',
      ssh_client_dict
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


def install_replicators(physical_env_params, ssh_client_dict):
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = config.CURRENT_PATH+'/rubble_ycsb'
  for server_ip in server_ips:
    logging.info("Installing replicator on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      run_script_on_local_machine(
        rubble_script_path+'/ycsb_setup.sh',
        params='--ycsb-branch=singleOp --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path'])
      )
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_path+'/ycsb_setup.sh',
        ssh_client_dict,
        params='--ycsb-branch=singleOp --rubble-path={}'.format(physical_env_params['server_info'][server_ip]['work_path']),
      )


def setup_m510(physical_env_params, ssh_client_dict):
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = config.CURRENT.rsplit('/', 1)[0]+'/setup_scripts/setup_single_env.sh'
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


def setup_physical_env(physical_env_params, ssh_client_dict, is_m510=False):
  if is_m510:
    # Run cloudlab specific init scripts.
    setup_m510(physical_env_params, ssh_client_dict)

  # Conigure SST file shipping path.
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict)
  elif physical_env_params['network_protocol'] == 'NVMe-oF-TCP':
    setup_NVMe_oF_i10(physical_env_params, ssh_client_dict)

  # Install RocksDB on every nodes.
  install_rocksdbs(physical_env_params, ssh_client_dict)

  # Install YCSB on the head node.
  install_ycsb(physical_env_params, ssh_client_dict)

  # Install rubble clients on every nodes.
  install_rubble_clients(physical_env_params, ssh_client_dict)

  # Install replicator on every nodes.
  install_replicators(physical_env_params, ssh_client_dict)


def run_rocksdb_server(ip, ssh_client_dict):
  logging.info("Under Development")


def start_test(physical_env_params, rubble_params, ssh_client_dict):
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  ycsb_script_path = config.CURRENT_PATH+'/rubble_ycsb'
  count = 0
  
  # Bring up all RocksDB Clients
  for shard in rubble_params['shard_info']:
    count += 1
    if count == 2:
      break
    logging.info("Bringing up chain {}".format(shard['tag']))
    chain_len = len(shard['sequence'])
    rocksdb_config = configparser.ConfigParser()
    rocksdb_config.read('rubble_rocksdb/rocksdb_config_file.ini')
    if chain_len == 1:
      next_port = physical_env_params['operator_ip']
      ip = shard['sequence'][0]['ip']
      rocksdb_config['DBOptions']['is_rubble'] = 'true'
      rocksdb_config['DBOptions']['is_primary'] = 'true'
      rocksdb_config['DBOptions']['is_tail'] = 'true'
      with open('/tmp/rubble_scripts/rocksdb_config_file.ini', 'w') as configfile:
        rocksdb_config.write(configfile)
      process = subprocess.Popen(
        'cp /tmp/rubble_scripts/rocksdb_config_file.ini {}/my_rocksdb/rubble/'.format(
          physical_env_params['server_info'][ip]['work_path']
        ), 
        shell=True, stdout=sys.stdout, stderr=sys.stderr
      )
      process.wait()
      run_script_helper(
        ip,
        rubble_script_path+'/rubble_client_run.sh',
        ssh_client_dict,
        params='--rubble-branch={} --rubble-path={} --rubble-mode={} --next-port={}'.format(
          physical_env_params['rocksdb']['branch'],
          physical_env_params['server_info'][ip]['work_path'],
          'vanilla',
          next_port
        ),
        background=True
      )
    else:
      for i in range(chain_len):
        ip = shard['sequence'][i]['ip']
        logging.info("Bring up rubble client on {}...".format(ip))
        next_port = shard['sequence'][i]['port']
        mode = 'vanilla'
        rubble_branch = physical_env_params['rocksdb']['branch']
        work_path = physical_env_params['server_info'][ip]['work_path']
        if i == 0:
          # Setup head node
          mode = 'primary'
          port = shard['sequence'][i+1]['ip']
          rocksdb_config['DBOptions']['is_rubble'] = 'true'
          # rocksdb_config['DBOptions']['is_primary'] = 'true'
          # rocksdb_config['DBOptions']['is_tail'] = 'false'
        elif i == chain_len-1:
          # Setup tail node
          mode = 'tail'
          port = physical_env_params['operator_ip']
          rocksdb_config['DBOptions']['is_rubble'] = 'true'
          # rocksdb_config['DBOptions']['is_primary'] = 'false'
          # rocksdb_config['DBOptions']['is_tail'] = 'true'
        else:
          # Setup regular node
          mode = 'secondary'
          port = shard['sequence'][i+1]['ip']
          rocksdb_config['DBOptions']['is_rubble'] = 'true'
          # rocksdb_config['DBOptions']['is_primary'] = 'false'
          # rocksdb_config['DBOptions']['is_tail'] = 'false'
        with open('/tmp/rubble_scripts/rocksdb_config_file.ini', 'w') as configfile:
          rocksdb_config.write(configfile)
        if ip == physical_env_params['operator_ip']:
          process = subprocess.Popen(
            'cp /tmp/rubble_scripts/rocksdb_config_file.ini {}/my_rocksdb/rubble/'.format(
              physical_env_params['server_info'][ip]['work_path']
            ), 
            shell=True, stdout=sys.stdout, stderr=sys.stderr
          )
          process.wait()
        else:
          transmit_file_to_remote_machine(
            ip, '/tmp/rubble_scripts/rocksdb_config_file.ini',
            '{}/my_rocksdb/rubble'.format(
              physical_env_params['server_info'][ip]['work_path']
            ),
            ssh_client_dict
          )
        run_script_helper(
          ip,
          rubble_script_path+'/rubble_client_run.sh',
          ssh_client_dict,
          params='--rubble-branch={} --rubble-path={} --rubble-mode={} --next-port={}'.format(
            rubble_branch,
            work_path,
            mode,
            next_port
          ),
          additional_scripts_paths=[]
        )

  # Bring up Replicator and run test
  

  # Generate the replicator configuration file
  

  # Copy the replicator configuration file to target dir.
  run_script_helper(
    ip=physical_env_params['operator_ip'],
    script_path=ycsb_script_path+'/ycsb_run.sh',
    ssh_client_dict=ssh_client_dict,
    params='--ycsb-branch={} --rubble-path={} --ycsb-mode={} --thread-num={} --replicator-addr={} --replicator-batch-size={} --workload={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['server_info'][ip]['work_path'],
      'load',
      physical_env_params['rubble_params']['chan_num'],
      physical_env_params['rubble_params']['replicator_address'], #replicator-addr
      physical_env_params['rubble_params']['batch_size'], #replicator-batch-size
      physical_env_params['rubble_params']['ycsb_workload'], #workload
    ),
    additional_scripts_paths=[],
  )





def test_script(ssh_client_dict, physical_env_params, rubble_params):
  start_test(physical_env_params, rubble_params, ssh_client_dict)
  # logging.info(list(physical_env_params['server_info'].keys()))
  # install_rocksdbs(physical_env_params, ssh_client_dict)
  # rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  # run_script_on_remote_machine(
  #   '10.10.1.2',
  #   rubble_script_path+'/rubble_client_setup.sh',
  #   ssh_client_dict
  # )
  # run_script_on_remote_machine_background(
  #   '10.10.1.2',
  #   rubble_script_path+'/rubble_client_run.sh',
  #   ssh_client_dict,
  #   params='--RUBBLE_MODE=vanilla --NEXT_PORT=10.10.1.1:50050'
  # )
  # run_script_on_remote_machine(
  #   '10.10.1.2',
  #   config.CURRENT_PATH+'/rubble_ycsb/ycsb_setup.sh',
  #   ssh_client_dict
  # )
  # run_script_on_remote_machine_background(
  #   '10.10.1.2',
  #   config.CURRENT_PATH+'/rubble_ycsb/replicator_setup.sh',
  #   ssh_client_dict
  # )
  # run_command_on_remote_machine(
  #   '10.10.1.2',
  #   'whoami',
  #   ssh_client_dict,
  #   ''
  # )

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
    close_ssh_clients(ssh_client_dict)
    exit(1)

  config_dict = dict()
  read_config(config_dict)
  logging.info("test configs: "+pformat(config_dict))
  check_config(config_dict)
  physical_env_params = config_dict['physical_env_params']
  request_params = config_dict['request_params']
  rubble_params = config_dict['rubble_params']
  config.OPERATOR_IP=physical_env_params['operator_ip']
  ssh_client_dict = init_ssh_clients(physical_env_params)
  if args.test:
    test_script(ssh_client_dict, physical_env_params, rubble_params)
    close_ssh_clients(ssh_client_dict)
    exit(1)

  setup_physical_env(physical_env_params, ssh_client_dict, is_m510)

  close_ssh_clients(ssh_client_dict)


if __name__ == '__main__':
  main()
