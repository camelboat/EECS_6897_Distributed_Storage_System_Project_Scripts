import config
import configparser
import logging
import os
import random
import time
from pprint import pformat

from utils.config import read_config, check_config
from ssh_utils.ssh_utils import read_log_file_last_lines, run_script_helper, \
  run_script_on_local_machine, run_script_on_remote_machine, \
		run_script_on_remote_machine_background, init_ssh_clients, \
      close_ssh_clients, run_command_on_remote_machine, \
        transmit_file_to_remote_machine, read_log_file_last_lines

loggingFilePath = '/mnt/sdb/logs/termination.log'
with open(loggingFilePath, 'w+'):
	print("Preparing logging file for experiment...")
logging.basicConfig(
	filename=loggingFilePath,
	filemode='a',
	format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
  datefmt='%H:%M:%S',
	level=logging.INFO)

config.CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

def rubble_cleanup(physical_env_params, ssh_client_dict, copy=False, backup=False):
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


def setup():
	config_dict = dict()
	read_config(config_dict)
	# logging.info("test configs: "+pformat(config_dict))
	check_config(config_dict)
	physical_env_params = config_dict['physical_env_params']
	rubble_params = config_dict['rubble_params']
	ip_map = config_dict['ip_map']

	ssh_client_dict = init_ssh_clients(physical_env_params)
	config.OPERATOR_IP=physical_env_params['operator_ip']
	return physical_env_params, rubble_params, ip_map, ssh_client_dict


def run_rocksdb_servers(physical_env_params, rubble_params, ssh_client_dict, is_rubble='true'):

  rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
  
  # Cleanup before each run
  rubble_cleanup(physical_env_params, ssh_client_dict)
    
  # Bring up all RocksDB Clients
  for shard in rubble_params['shard_info']:
    logging.info("Bringing up chain {}".format(shard['tag']))
    chain_len = len(shard['sequence'])

    for i in range(chain_len-1, -1, -1):
      ip = shard['sequence'][i]['ip']
      logging.info("Bring up rubble client on {}...".format(ip))
      port = ip + ":" + str(shard['sequence'][i]['port'])
      mode = 'vanilla'
      rubble_branch = physical_env_params['rocksdb']['branch']
      work_path = physical_env_params['server_info'][ip]['work_path']
      if chain_len == 1:
        mode = 'vanilla'
        port = rubble_params['replicator_ip'] + ":" + str(rubble_params['replicator_port'])
      elif i == 0:
        # Setup head node
        mode = 'primary'
        port = shard['sequence'][i+1]['ip'] + ":" + str(shard['sequence'][i+1]['port'])
      elif i == chain_len-1:
        # Setup tail node
        mode = 'tail'
        port = rubble_params['replicator_ip'] + ":" + str(rubble_params['replicator_port'])
      else:
        # Setup regular node
        mode = 'secondary'
        port = shard['sequence'][i+1]['ip'] + ":" + str(shard['sequence'][i+1]['port'])

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

  # Bring up Replicator
  run_script_helper(
    ip=physical_env_params['operator_ip'],
    script_path=ycsb_script_path+'/replicator_run.sh',
    ssh_client_dict=ssh_client_dict,
    params='--ycsb-branch={} --rubble-path={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['operator_work_path'],
    ),
  )  

def run_ycsb(physical_env_params, rubble_params, ssh_client_dict, op='load'):
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
      rubble_params['replicator_ip']+':'+str(rubble_params['replicator_port']), #replicator-addr
      rubble_params['batch_size'], #replicator-batch-size
      rubble_params['ycsb_workload'], #workload
    ),
    additional_scripts_paths=[],
  )

def find_primary_ips(rubble_params):
	ips = []
	for shard in rubble_params['shard_info']:
		ips.append(shard['sequence'][0]['ip'])
	return ips

def find_tail_ips(rubble_params):
	ips = []
	for shard in rubble_params['shard_info']:
		ips.append(shard['sequence'][-1]['ip'])
	return ips

def killProcess(ip_address, pattern, ssh_client_dict):
	rubble_script_path = config.CURRENT_PATH+'/rubble_rocksdb'
	run_script_helper(
		ip_address,
		rubble_script_path+'/killProcess.sh',
		ssh_client_dict,
		params='--pattern={}'.format(
			pattern,
		),
		additional_scripts_paths=[]
	)

def main():
	logging.info("Running random termination test for recovery")

	# parameterize the number of runs
	# TODO: put this into a config file in the future if reusing this script
	roundsOfExperiment = 90 # TODO: change this to 50 once done testing
	
	# setup ssh clients
	physical_env_params, rubble_params, ip_map, ssh_client_dict = setup()

	for i in range(roundsOfExperiment):
		logging.info("Experiment #%d", i)

		# clean up from previous round and start all db servers in order
		# TODO: assert that they start normally
		run_rocksdb_servers(physical_env_params, rubble_params, ssh_client_dict, is_rubble='true')

		# replicator cleanup and start a new replicator
		run_replicator(physical_env_params, ssh_client_dict)
		
		# determine when to terminate primary db server through random number generator
		# reference: it takes replicator ~100 seconds to distribute the requests to 1 shard
		#   ofc this is subject to ycsb request rate setting
		sleepSeconds = random.randint(1, 91)
		primary_addr = find_primary_ips(rubble_params)[0]  # TODO: this is hardcoded for now

		# start YCSB
		run_ycsb(physical_env_params, rubble_params, ssh_client_dict)

		# sleep for a pre-determined amount of time, wake up and terminate primary
		logging.info("Sleeping for %d seconds before terminating primary", sleepSeconds)
		time.sleep(sleepSeconds)
		killProcess(primary_addr, "primary_node", ssh_client_dict)
		
		# sleep again for enough time to allow a potentially good experiment to finish
		time.sleep(180 - sleepSeconds)

		# Collect results
		logging.info("Collecting results for experiment #%d", i)
		tail_ip = find_tail_ips(rubble_params)[0] # TODO: like primary, this is also hardcoded
		tail_last_line = read_log_file_last_lines(
			tail_ip, '/mnt/sdb/my_rocksdb/rubble/tail_log.txt', ssh_client_dict)
		logging.info("Sleep seconds: %d | Last line: %s", sleepSeconds, tail_last_line)
		
		
		
	
	close_ssh_clients(ssh_client_dict)

if __name__ == '__main__':
  main()