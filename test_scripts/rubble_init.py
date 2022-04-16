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

"""

from pprint import pformat
import logging
import os
import subprocess
import threading
import time
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
from utils.rubble_setup import setup_rubble_env

config.CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

logging.basicConfig(level=logging.INFO)

operator_ip = ''




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
  
  


def rubble_cleanup(physical_env_params,ssh_client_dict, copy=False, backup=False):
  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  server_ips = list(physical_env_params['server_info'].keys())
  for server_ip in server_ips:
    logging.info("rubble cleanup on {}...".format(server_ip))
    run_script_helper(
      server_ip,
      rubble_script_path+'/rubble_cleanup.sh',
      ssh_client_dict,
      params='--copy={} --backup={}'.format(copy, backup)
    )

def run_rocksdb_servers(physical_env_params, rubble_params, ssh_client_dict, ip_map, is_rubble='true'):

  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  
  # Cleanup before each run
  # TODO: fix copy flag for now
  rubble_cleanup(physical_env_params, ssh_client_dict, False)
    
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

def base_ycsb(physical_env_params, rubble_params, ssh_client_dict, ip_map, op='run'):
  ycsb_script_path = config.CURRENT_PATH+'/rubble_ycsb'
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
  # rubble_cleanup(physical_env_params,ssh_client_dict, backup=True)
  # base_ycsb(physical_env_params, rubble_params, ssh_client_dict, ip_map,'run')


def parseConfig():
  config_dict = dict()
  read_config(config_dict)
  logging.info("test configs: "+pformat(config_dict))
  check_config(config_dict)
  physical_env_params = config_dict['physical_env_params']
  request_params = config_dict['request_params']
  rubble_params = config_dict['rubble_params']
  config.OPERATOR_IP=physical_env_params['operator_ip']
  ssh_client_dict = init_ssh_clients(physical_env_params)
  return physical_env_params, request_params, rubble_params, ssh_client_dict


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
  
  physical_env_params, request_params, rubble_params, ssh_client_dict = parseConfig()
  # TODO: whether or not to run is_rubble should be listed in test_config.yml

  if args.setup:
    setup_rubble_env(physical_env_params, rubble_params, ssh_client_dict, config.CURRENT_PATH)

  # if args.test:
  #   test_script(physical_env_params, rubble_params, ssh_client_dict)
    # close_ssh_clients(ssh_client_dict)
    # exit(1)
  
  close_ssh_clients(ssh_client_dict) # dryrun will only execute this


if __name__ == '__main__':
  main()
