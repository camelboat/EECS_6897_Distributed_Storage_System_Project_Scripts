import yaml
from pprint import pformat
import logging
import os
import yamale
import subprocess

logging.basicConfig(level=logging.DEBUG)

CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

physical_env_params=dict()
request_params=dict()
rubble_params=dict()
operator_ip = ''


def run_script_on_machine(ip_address: str, script_path: str, params: str=''):
  """Run bash script on a machine

  Run bash script with parameters on a machine with a specific IP address. If
  it is the local machine, run script locally. Else, use ssh to login the machine
  and run the script remotely.

  Args:
    ip_address:
      IP address of the machine that we want to run the script.
    script_path:
      Path to the script.
    params:
      Script parameters in the string format. It is caller's responsibility to prepare
      the parameter string in a correct format given that different script may have
      different style of arguments parsing.
  """
  global physical_env_params
  if physical_env_params['operator_ip'] == ip_address:
    run_script_on_local_machine(script_path, params='')
  else:
    run_script_on_remote_machine(ip_address, script_path, params='')


def run_script_on_local_machine(script_path, params):
  cmd = script_path + ' ' + params
  logging.info(cmd)
  process = subprocess.Popen(
    cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
  )
  while process.poll() is None:
    line = process.stdout.readline()
    print(line.decode("utf-8").rsplit('\n', 1)[0])
  # output = subprocess.check_output(cmd, shell=True)
  # print(output)

def run_script_on_remote_machine(ip_address, script_path, params):
  return "HI"


def read_config(config_dict):
  with open(CURRENT_PATH+'/test_config.yml') as test_config_file:
    config_dict.update(yaml.load(test_config_file, Loader=yaml.FullLoader))


def check_config(config_dict):
  schema = yamale.make_schema(CURRENT_PATH+'/test_config_schema.yml')
  data = yamale.make_data(CURRENT_PATH+'/test_config.yml')
  try:
    yamale.validate(schema, data)
  except ValueError as e:
    logging.error('test_config.yml validation failed\n{}'.format(str(e)))
    exit(1)
  assert config_dict['physical_env_params']['server_num'] == \
    len(config_dict['physical_env_params']['server_ips']), \
    "Server Number is not equal to number of server IP addresses"
  assert config_dict['physical_env_params']['server_num'] == \
    len(config_dict['physical_env_params']['block_devices']), \
    "Server Number is not equal to number of block devices"
  assert config_dict['request_params']['read_ratio'] + \
    config_dict['request_params']['update_ratio'] == 100, \
      "read_ratio + update_ratio is not 100"


def setup_NVMe_oF_RDMA(physical_env_params):
  # We setup NVMe-oF through RDMA on every neighbor server pairs in chain.
  server_ips = physical_env_params['server_ips']
  block_devices = physical_env_params['block_devices']
  server_ips_pairs = [[server_ips[i], server_ips[i+1], block_devices[i+1]] for i in range(len(server_ips)-1)]
  NVMe_oF_RDMA_script_path = CURRENT_PATH.rsplit('/', 1)[0]+'/setup_scripts/NVME_over_Fabrics'
  for ip_pairs in server_ips_pairs:
    client_ip = ip_pairs[0]
    target_ip = ip_pairs[1]
    target_device = ip_pairs[2]
    logging.info('Setting up NVMe-oF for {}'.format(ip_pairs))
    logging.info('Client IP: {}'.format(client_ip))
    logging.info('Target IP: {}'.format(target_ip))
    logging.info('Target Device: {}'.format(target_device))
    logging.info('NVMe-oF-RDMA script path: {}'.format(NVMe_oF_RDMA_script_path))
    run_script_on_machine(client_ip, NVMe_oF_RDMA_script_path+'/client_setup.sh')


def setup_physical_env(physical_env_params):
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params)


def main():
  global physical_env_params
  global request_params
  global rubble_params
  config_dict = dict()
  read_config(config_dict)
  logging.info("test configs: "+pformat(config_dict))
  check_config(config_dict)
  physical_env_params = config_dict['physical_env_params']
  request_params = config_dict['request_params']
  rubble_params = config_dict['rubble_params']
  setup_physical_env(physical_env_params)


if __name__ == '__main__':
  main()
