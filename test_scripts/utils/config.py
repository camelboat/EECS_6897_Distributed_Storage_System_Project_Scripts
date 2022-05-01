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
  assert config_dict['rubble_params']['request_params']['read_ratio'] + \
    config_dict['rubble_params']['request_params']['update_ratio'] == 100, \
      "read_ratio + update_ratio is not 100"
  # TODO: Add more assertions.
  # TODO: Move all assertion to test_config_schema.yml
