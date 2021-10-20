from generator import generator
import os
import yaml


if "name" not in os.environ:
    print("Usage: name=xxxx terraformpy where xxxx is the name of this deployment.  used to maintain isolation between deployments")
    exit(1)

config_file_name = os.getenv("config", "config.yaml")

f = open(config_file_name, "r")
config_file = yaml.load(f, Loader=yaml.FullLoader)
generator.generate(config_file)
