import yaml
from pprint import pformat
import logging
import os
import yamale
import subprocess
from colored import fg, bg, attr
import paramiko

logging.basicConfig(level=logging.INFO)

CURRENT_PATH=os.path.dirname(os.path.abspath(__file__))

physical_env_params=dict()
request_params=dict()
rubble_params=dict()
operator_ip = ''


def print_success(out: str):
  color = fg('6')
  res = attr('reset')
  print(color + out + res)


def print_error(out: str):
  color = fg('1')
  res = attr('bold')+attr('reset')
  print(color + out + res)


def print_script_stdout(out: str):
  color = fg('2')
  res = attr('reset')
  print(color + out + res)


def print_script_stderr(out: str):
  color = fg('8')+bg('235')
  res = attr('bold')+attr('reset')
  print(color + out + res)


def run_script_on_local_machine(script_path, params=''):
  """Run bash script on the local machine

  Run bash script with parameters on the local machine.

  Args:
    script_path:
      Path to the script.
    params:
      Script parameters in the string format. It is caller's responsibility to prepare
      the parameter string in a correct format given that different script may have
      different style of arguments parsing.
  """

  cmd = script_path + ' ' + params
  logging.info(cmd)
  process = subprocess.Popen(
    cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
  )
  while process.poll() is None:
    line = process.stdout.readline()
    err_line = process.stderr.readline()
    print_script_stdout(line.decode('utf-8').rsplit('\n', 1)[0])
    print_script_stderr(err_line.decode('utf-8').rsplit('\n', 1)[0])
  # output = subprocess.check_output(cmd, shell=True)
  # print(output)

def run_script_on_remote_machine(ip_address, script_path, ssh_client_dict, params=''):
  """Run bash script on a remote machine

  Run bash script with parameters on a machine with a specific IP address. Use ssh 
  to login the machine and run the script remotely.

  Args:
    ip_address:
      IP address of the machine that we want to run the script.
    script_path:
      Path to the script.
    ssh_client_dict:
      A dict of pamamiko ssh clients. Clients should have been already connected to the
      target.
    params:
      Script parameters in the string format. It is caller's responsibility to prepare
      the parameter string in a correct format given that different script may have
      different style of arguments parsing.
  """
  
  client = ssh_client_dict[ip_address]
  # Transmit the scritps to the remote machine then execute it.
  script_name = script_path.rsplit('/', 1)[1]
  remote_script_path = '/tmp/rubble_scripts/{}'.format(script_name)
  sftp_client = client.open_sftp()
  sftp_client.put(script_path, remote_script_path)
  sftp_client.close()
  stdin, stdout, stderr = client.exec_command(
    'bash '+remote_script_path+' '+params, get_pty=True
  )
  for line in stdout.readlines():
    print(line)


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
  # TODO: Add more assertions.


def init_ssh_clients(physical_env_params: dict):
  ssh_client_dict = dict()
  for i in range(physical_env_params['server_num']):
    server_ip = physical_env_params['server_ips'][i]
    server_user = physical_env_params['server_users'][i]
    if not server_ip == physical_env_params['operator_ip']:
      client = paramiko.SSHClient()
      client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
      client.connect(
        hostname=server_ip,
        username=server_user,
        key_filename=physical_env_params['operator_key_path']
      )
      logging.info('Generate ssh connection with {}'.format(server_ip))
      stdin, stdout, stderr = client.exec_command('echo Hello!')
      print_success(stdout.readlines()[0]+' from {}'.format(server_ip))
      stdin, stdout, stderr = client.exec_command('mkdir -p /tmp/rubble_scripts')
      ssh_client_dict[server_ip] = client
  return ssh_client_dict


def close_ssh_clients(ssh_client_dict: dict):
  for server_ip, ssh_client in ssh_client_dict.items():
    ssh_client.close()


def setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict):
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
    run_script_on_local_machine(NVMe_oF_RDMA_script_path+'/client_setup.sh')
    run_script_on_remote_machine(
      target_ip,
      NVMe_oF_RDMA_script_path+'/target_setup.sh',
      ssh_client_dict,
      params='--target-ip-address='.format(target_ip)
    )


def setup_physical_env(physical_env_params, ssh_client_dict):
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict)


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

  ssh_client_dict = init_ssh_clients(physical_env_params)
  setup_physical_env(physical_env_params, ssh_client_dict)
  close_ssh_clients(ssh_client_dict)


if __name__ == '__main__':
  main()
