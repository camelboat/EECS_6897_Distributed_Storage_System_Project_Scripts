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

from utils.config import read_config, check_config
from utils.utils import print_success, print_error, print_script_stdout, print_script_stderr
from ssh_utils.ssh_utils import run_script_on_local_machine, run_script_on_remote_machine, run_script_on_remote_machine_background, init_ssh_clients, close_ssh_clients, run_command_on_remote_machine

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
        params='--target-ip-address={} --subsystem-name={}'.format(target_ip, nvme_of_namespace)
      )
    else:
      run_script_on_remote_machine(
        target_ip,
        NVMe_oF_RDMA_script_path+'/target_setup.sh',
        ssh_client_dict,
        params='--target-ip-address={} --subsystem-name={}'.format(target_ip, nvme_of_namespace)
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
  head_ip = physical_env_params['server_ips'][0]



def setup_physical_env(physical_env_params, ssh_client_dict):
  # Conigure SST file shipping path.
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict)
  elif physical_env_params['network_protocol'] == 'NVMe-oF-TCP':
    setup_NVMe_oF_i10(physical_env_params, ssh_client_dict)

  # Install RocksDB on every nodes.
  # install_rocksdbs(physical_env_params, ssh_client_dict)

  # Install YCSB on the head node.
  


def test_script(ssh_client_dict, physical_env_params):
  logging.info(list(physical_env_params['server_info'].keys()))
  install_rocksdbs(physical_env_params, ssh_client_dict)
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
  ssh_client_dict = init_ssh_clients(physical_env_params)
  if args.test:
    test_script(ssh_client_dict, physical_env_params)
    close_ssh_clients(ssh_client_dict)
    exit(1)

  setup_physical_env(physical_env_params, ssh_client_dict)

  close_ssh_clients(ssh_client_dict)


if __name__ == '__main__':
  main()
