import logging
import threading
import config
import time

from ssh_utils.ssh_utils import run_script_helper, \
  run_script_on_local_machine, run_script_on_remote_machine, \
    run_script_on_remote_machine_background, init_ssh_clients, \
      close_ssh_clients, run_command_on_remote_machine, \
        transmit_file_to_remote_machine


def setup_m510(physical_env_params, ssh_client_dict, current_path):
  """
  setup_m510 runs setup_single_env.sh, which formats the block device,
  mount it to /mnt/{code, db, sst}, and installs some dependencies.
  """

  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_dir = current_path.rsplit('/', 1)[0]+'/setup_scripts/'
  for server_ip in server_ips:
    logging.info("Initial m510 setup on {}...".format(server_ip))
    if (server_ip == physical_env_params['operator_ip']):
      continue
    else:
      run_script_on_remote_machine(
        server_ip,
        rubble_script_dir + 'setup_single_env.sh',
        ssh_client_dict,
        '',
        [rubble_script_dir + 'disk_partition.sh']
      )


def install_rocksdbs(physical_env_params, ssh_client_dict, current_path):
  """
  install_rocksdbs installs rocksdb and rubble_server on all nodes 
  except the operator node.
  """
  server_ips = list(physical_env_params['server_info'].keys())
  rubble_script_path = current_path+'/rubble_rocksdb'
  gRPC_path = current_path.rsplit('/', 1)[0]+'/setup_scripts/gRPC'
  threads = []
  for server_ip in server_ips:
    logging.info("Installing RocksDB on {}...".format(server_ip))
    if (server_ip != physical_env_params['operator_ip']):
      t = threading.Thread(target=run_script_on_remote_machine,
                           args=(server_ip,
                                 rubble_script_path+'/rocksdb_setup.sh',
                                 ssh_client_dict,
                                 '--rubble-branch={} --rubble-path={}'.format(
                                   physical_env_params['rocksdb']['branch'],
                                   physical_env_params['server_info'][server_ip]['work_path']),
                                 [ gRPC_path+'/cmake_install.sh',
                                   gRPC_path+'/grpc_setup.sh'] )
                            )
      threads.append(t)
      t.start()
  for t in threads:
    t.join()

def preallocate_slots_remount(physical_env_params, rubble_params, ssh_client_dict, current_path):
  """
  preallocate_slots pre-allocates sst slots in the specified directory,
  this should be done BEFORE mounting the block device onto the remote directory.
  """
  rubble_branch = physical_env_params['rocksdb']['branch']
  rubble_script_path = current_path+'/rubble_rocksdb/rubble_client_run.sh'
  threads = []
  
  # TODO: extend this function to work with 3-node setup
  # TODO: parameterize the number of slots to pre-allocate

  for shard in rubble_params['shard_info']:
    logging.info("Bring up tail client on chain {} to pre-allocate slots".format(shard['tag']))
    ip = shard['sequence'][-1]['ip']
    port = rubble_params['replicator_ip'] + ":" + str(rubble_params['replicator_port'])
    work_path = physical_env_params['server_info'][ip]['work_path']
    db_path = physical_env_params['server_info'][ip]['db_path']
    t = threading.Thread(target=run_script_helper,
                         args=(ip, rubble_script_path, ssh_client_dict,
                         '--rubble-branch={} --rubble-path={} --db-path={} \
                           --rubble-mode={} --next-port={}'.format(
                            rubble_branch,
                            work_path+'/my_rocksdb/rubble',
                            db_path,
                            'tail',
                            port
                          ),[]))
    threads.append(t)
    t.start()
  for t in threads:
    t.join()
  # sleep for 4 minutes until all slots are allocated
  time.sleep(360)

  # remount the local sst slot directory as a read-only partition to
  # ensure file system integrity
  remount_script_dir = current_path.rsplit('/', 1)[0]+'/setup_scripts/'
  for shard in rubble_params['shard_info']:
    logging.info("Remount sst slot dir on chain {} as read-only".format(shard['tag']))
    ip = shard['sequence'][-1]['ip']
    run_script_helper(
      ip,remount_script_dir + 'remount_readonly.sh', ssh_client_dict)

  


def setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict):
  """
  setup_NVMe_oF_RDMA etups NVMe-oF through RDMA on every neighbor server pairs in chain.
  NOTE that this function ASSUMES that the replication replication chains follows
    the sequence of the server_info IP addresses list. For example, if we have 
    server_info: [A, B, C] as keys, this function will establish RDMA conn
    as such: A->B->C AND C->B->A, where `->` means a rdma client->target relationship.
  """
  server_ips = list(physical_env_params['server_info'].keys())
  block_devices = [ server['block_device']['device_path'] for server in physical_env_params['server_info'].values() ]
  server_pairs1 = [[server_ips[i], server_ips[i+1], block_devices[i+1]] for i in range(len(server_ips)-1)]
  server_pairs2 = [[server_ips[i+1], server_ips[i], block_devices[i]] for i in range(len(server_ips)-1)]
  server_pairs = server_pairs1 + server_pairs2
  print("[**********block device*************]", block_devices[0])
  NVMe_oF_RDMA_script_path = config.CURRENT_PATH.rsplit('/', 1)[0]+'/setup_scripts/NVME_over_Fabrics'
  for server_pair in server_pairs:
    client_ip = server_pair[0]
    target_ip = server_pair[1]
    target_device = server_pair[2]
    mounting_point = physical_env_params['server_info'][client_ip]['remote_device_mnt_path']
    nvme_of_namespace = physical_env_params['server_info'][target_ip]['block_device']['nvme_of_namespace']
    logging.info('Setting up NVMe-oF for {}'.format(server_pair))
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
        params='--is-connect=true --target-ip-address={} --subsystem-name={} \
          --remote-device={} --mounting-point={}'.format(
          target_ip, nvme_of_namespace, target_device, mounting_point)
      )  
    else:
      run_script_on_remote_machine(
        client_ip, 
        NVMe_oF_RDMA_script_path+'/client_setup.sh', 
        ssh_client_dict,
        params='--is-connect=true --target-ip-address={} --subsystem-name={} \
          --remote-device={} --mounting-point={}'.format(
          target_ip, nvme_of_namespace, target_device, mounting_point)
      )


def setup_NVMe_oF_TCP(physical_env_params, ssh_client_dict):
  logging.warning("NVMe-oF through TCP setup has not been implemented")
  exit(1)


def setup_NVMe_oF_i10(physical_env_params, ssh_client_dict):
  logging.warning("i10 needs manual setup since it relies on a specific version of Linux kernel")
  exit(1)

  

def install_ycsb(physical_env_params, current_path):
  """
  install_ycsb installs replicator and ycsb on the operator node,
  which is the default node to run YCSB + replicator.
  """
  run_script_on_local_machine(
    current_path+'/rubble_ycsb/ycsb_setup.sh',
    params='--ycsb-branch={} --work-path={}'.format(
      physical_env_params['ycsb']['replicator']['branch'],
      physical_env_params['operator_work_path']
    )
  )




def setup_rubble_env(physical_env_params, rubble_params, ssh_client_dict, current_path):
  """
  setup_rubble_env invokes functions to set up NVMEoF, install rocksdb, pre-allocate slots, and
  install YCSB. This is the entry point of all setup functions.
  """

  # Run cloudlab specific init scripts.
  setup_m510(physical_env_params, ssh_client_dict, current_path)

  # Install RocksDB and Rubble on every nodes.
  install_rocksdbs(physical_env_params, ssh_client_dict, current_path)
  
  preallocate_slots_remount(physical_env_params, rubble_params, ssh_client_dict, current_path)


  # Conigure SST file shipping path.
  if physical_env_params['network_protocol'] == 'NVMe-oF-RDMA':
    setup_NVMe_oF_RDMA(physical_env_params, ssh_client_dict)
  elif physical_env_params['network_protocol'] == 'NVMe-oF-TCP':
    setup_NVMe_oF_i10(physical_env_params, ssh_client_dict)

  # Install YCSB on the head node.
  install_ycsb(physical_env_params, current_path)