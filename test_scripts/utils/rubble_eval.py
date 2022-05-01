import logging
import subprocess
import time
import sys
import config
import configparser

from utils.utils import print_success, print_error, print_script_stdout, print_script_stderr
from ssh_utils.ssh_utils import run_script_helper, \
  run_script_on_local_machine, run_script_on_remote_machine, \
    run_script_on_remote_machine_background, init_ssh_clients, \
      close_ssh_clients, run_command_on_remote_machine, \
        transmit_file_to_remote_machine

def rubble_cleanup(
  physical_env_params,ssh_client_dict, current_path, copy=False, backup=False):
  """
  rubble_cleanup cleans up the log and db files before each round of evaluation.
  """
  # TODO: fix this script to work with 3-node setup
  # TODO: evaluate the necessity of copy-pasting the sst files
  rubble_script_path = current_path + '/rubble_rocksdb'
  server_ips = list(physical_env_params['server_info'].keys())
  for server_ip in server_ips:
    logging.info("rubble cleanup on {}...".format(server_ip))
    run_script_helper(
      server_ip,
      rubble_script_path+'/rubble_cleanup.sh',
      ssh_client_dict,
      params='--copy={} --backup={}'.format(copy, backup)
    )

def run_rocksdb_servers(
  physical_env_params, rubble_params, ssh_client_dict, 
  current_path, is_rubble='true'):
  """
  run_rocksdb_servers ships the correct config files over and 
  brings up the replication chains of db server.
  """
  rubble_script_path = current_path +'/rubble_rocksdb'
  
  # Cleanup before each run
  rubble_cleanup(physical_env_params, ssh_client_dict, current_path)
    
  # Bring up all RocksDB Clients
  for shard in rubble_params['shard_info']:
    logging.info("Bringing up chain {}".format(shard['tag']))
    chain_len = len(shard['sequence'])

    rocksdb_config = configparser.ConfigParser()
    rocksdb_config.read('rubble_rocksdb/rocksdb_config_file.ini')

    # Configure the mode and port and is_rubble flag
    for i in range(chain_len-1, -1, -1):
      ip = shard['sequence'][i]['ip']
      logging.info("Bring up rubble client on {}...".format(ip))
      port = ip + ":" + str(shard['sequence'][i]['port'])
      work_path = physical_env_params['server_info'][ip]['work_path']
      rocksdb_config['DBOptions']['is_rubble'] = is_rubble
      mode = 'vanilla'
      if i == 0:
        # Setup head node
        mode = 'primary'
        port = shard['sequence'][i+1]['ip'] + ":" + str(shard['sequence'][i+1]['port'])
        rocksdb_config['CFOptions "default"']['max_write_buffer_number'] = "4"
      elif i == chain_len-1:
        # Setup tail node
        mode = 'tail'
        port = rubble_params['replicator_ip'] + ":" + str(rubble_params['replicator_port'])
        rocksdb_config['CFOptions "default"']['max_write_buffer_number'] = "64"
      else:
        # Setup regular node
        mode = 'secondary'
        port = shard['sequence'][i+1]['ip'] + ":" + str(shard['sequence'][i+1]['port'])
        rocksdb_config['CFOptions "default"']['max_write_buffer_number'] = "64"
        
      # transmit the ini file to the db server worker node
      filename = 'rocksdb_config_file{}.ini'.format(
        "" if i == 0 else "_tail")
      file_path = '/tmp/rubble_scripts/' + filename
      with open(file_path, 'w') as configfile:
        rocksdb_config.write(configfile)
      if ip == rubble_params['replicator_ip']:
        process = subprocess.Popen(
          'cp {} {}/my_rocksdb/rubble/'.format(
            file_path,
            work_path
          ), 
          shell=True, stdout=sys.stdout, stderr=sys.stderr
        )
        process.wait()
      else:
        transmit_file_to_remote_machine(
          ip, file_path,
          '{}/my_rocksdb/rubble/{}'.format(
            work_path,
            filename
          ),
          ssh_client_dict
        )
      # Bring up the db server
      run_script_helper(
        ip,
        rubble_script_path+'/rubble_client_run.sh',
        ssh_client_dict,
        params='--rubble-path={} --rubble-mode={} --next-port={}'.format(
          work_path+'/my_rocksdb/rubble',
          mode,
          port
        ),
        additional_scripts_paths=[]
      )


def run_replicator(physical_env_params, rubble_params, ssh_client_dict, current_path):
  """
  run_replicator brings up the replicator based on the configuration passed in.
  """

  # TODO: check with Haoyu about replicator merge

  ycsb_script_path = current_path + '/rubble_ycsb'
  replicator_ip = rubble_params['replicator_ip']
  replicator_port = rubble_params['replicator_port']
  workload = 'workloads/workload{}'.format(rubble_params['ycsb_workload'])
  shardNumber = rubble_params['shard_num']

  # TODO: might be necessary to write our own workload file and ship it over
  
  # build the replicator arguments
  args = "replicator rocksdb -s -P {} -p port={} -p shard={} -p replica={}".format(
    workload, replicator_port, shardNumber, rubble_params['replica_num'])
  
  for idx, shard in enumerate(rubble_params['shard_info']):
    head_ip = '{}:{}'.format(
      shard['sequence'][0]['ip'], shard['sequence'][0]['port'])
    tail_ip = '{}:{}'.format(
      shard['sequence'][-1]['ip'], shard['sequence'][-1]['port'])
    shardIndex = idx + 1
    args += ' -p head{}={} -p tail{}={}'.format(
      shardIndex, head_ip, shardIndex, tail_ip)

  # bring up the replicator
  run_script_helper(
    ip=replicator_ip,
    script_path=ycsb_script_path+'/replicator_setup.sh',
    ssh_client_dict=ssh_client_dict,
    params='--arguments="{}" --rubble-path={}'.format(
      args,
      physical_env_params['operator_work_path'])
  )  

def base_ycsb(physical_env_params, rubble_params, ssh_client_dict, current_path, phase):

  run_script_helper(
    ip=physical_env_params['operator_ip'],
    script_path=current_path+'/rubble_ycsb/ycsb_run.sh',
    ssh_client_dict=ssh_client_dict,
    params='--shard-number={} --rubble-path={} --ycsb-mode={} --thread-num={} \
    --replicator-addr={} --target-rate={} --workload={}'.format(
      rubble_params['shard_num'],
      physical_env_params['operator_work_path'],
      phase,
      rubble_params['thread_num'],
      rubble_params['replicator_ip']+':'+str(rubble_params['replicator_port']), #replicator-addr
      rubble_params['target_rate'], #replicator target rate
      rubble_params['ycsb_workload'], #workload
    ),
    additional_scripts_paths=[],
  )


# TODO: parameterize the remote sst dir as well

def rubble_eval(physical_env_params, rubble_params, ssh_client_dict, current_path):
  """
  rubble_eval runs one round of evaluation given the config. It is the entry
  point to all the eval functions that bring up different processes: db server,
  replicator, YCSB, and evaluation scripts.
  """

  # TODO: parameterize is_rubble flag in test_config.yml file
  run_rocksdb_servers(
    physical_env_params, rubble_params, ssh_client_dict, 
    current_path, is_rubble='false')

  run_replicator(physical_env_params, rubble_params, ssh_client_dict, current_path)

  base_ycsb(
    physical_env_params, rubble_params, ssh_client_dict, 
    current_path, 'load')
  
  base_ycsb(
    physical_env_params, rubble_params, ssh_client_dict, 
    current_path,'run')