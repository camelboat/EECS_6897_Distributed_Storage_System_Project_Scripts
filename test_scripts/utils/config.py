import yaml
import logging
import yamale
import config

def read_config(config_dict):
  with open(config.CURRENT_PATH+'/test_config.yml') as test_config_file:
    config_dict.update(yaml.load(test_config_file, Loader=yaml.FullLoader))

def check_config(config_dict):
  schema = yamale.make_schema(config.CURRENT_PATH+'/test_config_schema.yml')
  data = yamale.make_data(config.CURRENT_PATH+'/test_config.yml')
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
