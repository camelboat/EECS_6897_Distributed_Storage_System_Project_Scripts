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
import argparse
import config

from utils.config import read_config, check_config
from ssh_utils.ssh_utils import run_script_helper, \
  run_script_on_local_machine, run_script_on_remote_machine, \
    run_script_on_remote_machine_background, init_ssh_clients, \
      close_ssh_clients, run_command_on_remote_machine, \
        transmit_file_to_remote_machine
from utils.rubble_setup import setup_rubble_env
from utils.rubble_eval import rubble_eval

config.CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

logging.basicConfig(level=logging.INFO)

operator_ip = ''


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
    '--eval',
    help='Run evaluation for rubble, run after --setup is done',
    action="store_true"
  )

  args = parser.parse_args()
  
  physical_env_params, request_params, rubble_params, ssh_client_dict = parseConfig()
  # TODO: whether or not to run is_rubble should be listed in test_config.yml

  if args.setup:
    setup_rubble_env(physical_env_params, rubble_params, ssh_client_dict, config.CURRENT_PATH)

  if args.eval:
    rubble_eval(physical_env_params, rubble_params, ssh_client_dict, config.CURRENT_PATH)
  
  close_ssh_clients(ssh_client_dict) # dryrun will only execute this


if __name__ == '__main__':
  main()
