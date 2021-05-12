import logging
import os
import yaml
import yamale
import subprocess
import paramiko
import sys
import config

from utils.utils import print_success, print_error, print_script_stdout, print_script_stderr

def run_script_helper(ip, script_path, ssh_client_dict=dict(), params='', additional_scripts_paths=[], background=False):
  if ip == config.OPERATOR_IP:
      run_script_on_local_machine(script_path, params, additional_scripts_paths, background)
  else:
    if not background:
      run_script_on_remote_machine(ip, script_path, ssh_client_dict, params, additional_scripts_paths)
    else:
      run_script_on_remote_machine_background(ip, script_path, ssh_client_dict, params, additional_scripts_paths)


def run_script_on_local_machine(script_path, params='',  additional_scripts_paths=[], background=False):
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
  
  # Copy script to /tmp/rubble_scripts to make it align with remote run.
  script_name = script_path.rsplit('/', 1)[1]
  new_script_path = '/tmp/rubble_scripts/{}'.format(script_name)
  process = subprocess.Popen(
    'mkdir -p /tmp/rubble_scripts', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
  )
  process = subprocess.Popen(
    'cp {} {}'.format(script_path, new_script_path), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
  )
  for additional_script_path in additional_scripts_paths:
    additional_script_name = additional_script_path.rsplit('/', 1)[1]
    additional_new_script_path = '/tmp/rubble_scripts/{}'.format(additional_script_name)
    cmd = 'cp {} {}'.format(additional_script_path, additional_new_script_path)
    print_script_stdout(cmd)
    process = subprocess.Popen(
      cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
  cmd = 'bash ' + new_script_path + ' ' + params
  logging.info(cmd)
  if not background:
    process = subprocess.Popen(
      cmd, shell=True, stdout=sys.stdout, stderr=sys.stderr
    )
    process.wait()
  else:
    process = subprocess.Popen(
      cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

  # while process.poll() is None:
    # line = process.stdout.readline()
    # print_script_stdout(line.decode('utf-8').rsplit('\n', 1)[0])
    # err_line = process.stderr.readline()
    # print_script_stderr(err_line.decode('utf-8').rsplit('\n', 1)[0])


def run_script_on_remote_machine(ip_address, script_path, ssh_client_dict, params='', additional_scripts_paths=[]):
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
    additional_scripts:
      Scripts that may be triggered by the main script, so we also need to send them to
      the target server.      
  """

  # Transmit the scritps to the remote machine then execute it.
  script_name = script_path.rsplit('/', 1)[1]
  remote_script_path = '/tmp/rubble_scripts/{}'.format(script_name)
  transmit_file_to_remote_machine(ip_address, script_path, remote_script_path, ssh_client_dict)
  for addtional_script_path in additional_scripts_paths:
    additional_script_name = addtional_script_path.rsplit('/', 1)[1]
    additional_remote_script_path = '/tmp/rubble_scripts/{}'.format(additional_script_name)
    transmit_file_to_remote_machine(ip_address, addtional_script_path, additional_remote_script_path, ssh_client_dict)
  client = ssh_client_dict[ip_address]
  stdin, stdout, stderr = client.exec_command(
    'bash '+remote_script_path+' '+params, get_pty=True
  )
  for line in iter(lambda: stdout.readline(2048), ""):
    print_script_stdout(line.split('\n')[0])
  # for line in stdout.readlines():
  #   logging.info(line.split('\n')[0])
  
  # for line in stderr.readlines():
  #   logging.error(line.split('\n')[0])

def run_command_on_remote_machine(ip_address, command, ssh_client_dict, params=''):
  """Run bash command on a remote machine

  Args:
    ip_address:
      IP address of the machine that we want to run the script.
    command:
      String of bash command
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
  stdin, stdout, stderr = client.exec_command(
    command+' '+params
  )
  for line in iter(lambda: stdout.readline(2048), ""):
    print_script_stdout(line, end="")
  # for line in stdout.readlines():
  #   logging.info(line.split('\n')[0])
  # for line in stderr.readlines():
  #   logging.error(line.split('\n')[0])



def run_script_on_remote_machine_background(ip_address, script_path, ssh_client_dict, params=''):
  """Run bash script on a remote machine in the background

  Run bash script with parameters on a machine with a specific IP address. Use ssh 
  to login the machine and run the script remotely. The PID of the process spawn by that
  script would be written to /tmp/rubble_proc/proc_table for later process kill(it is 
  script's responsibility to write this information).

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
  

  # Transmit the scritps to the remote machine then execute it.
  script_name = script_path.rsplit('/', 1)[1]
  remote_script_path = '/tmp/rubble_scripts/{}'.format(script_name)
  transmit_file_to_remote_machine(ip_address, script_path, remote_script_path, ssh_client_dict)
  client = ssh_client_dict[ip_address]
  transport = client.get_transport()
  channel = transport.open_session()
  channel.exec_command(
    'bash '+remote_script_path+' '+params + ' > /dev/null 2>&1 &'
  )


def transmit_file_to_remote_machine(ip_address, file_path, remote_file_path, ssh_client_dict):
  logging.info("Transmit {} to {} in {}".format(file_path, ip_address, remote_file_path))
  client = ssh_client_dict[ip_address]
  sftp_client = client.open_sftp()
  sftp_client.put(file_path, remote_file_path)
  sftp_client.close()


def init_ssh_clients(physical_env_params: dict):
  ssh_client_dict = dict()
  for server_ip, server in physical_env_params['server_info'].items():
    server_user = server['user']
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
