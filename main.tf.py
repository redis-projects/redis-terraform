from terraformpy import Module, Provider, Data
from terraformpy.helpers import relative_file
import os
import yaml
from providers import aws, gcp, REGION, ZONE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION

gcp_provider = Provider("google", project="redislabs-sa-training-services", region=REGION, zone=ZONE, credentials=relative_file("./terraform_account.json"))
aws_provider = Provider("aws", region=AWS_REGION, access_key=AWS_ACCESS_KEY_ID, secret_key=AWS_SECRET_ACCESS_KEY)

#gcp_provider2 = Provider("google", project="redislabs-sa-training-services", region="us-east1", zone="us-east1-b", credentials=relative_file("./terraform_account.json"), alias="alternate")

random_id = Module("random_id", source="./modules/random_id") 

def generate(config_file):
    network_map = {}

    if 'networks' in config_file:
        for network in config_file['networks']:
            provider = network.pop('provider', "gcp")
            network_map[network["name"]] = provider
            if provider == "gcp":
                gcp.create_network(**network)
            elif provider == "aws":
                aws.create_network(**network)
            else: 
                print("unsupported provider {}".format(provider))
                exit(1)
    if 'clusters' in config_file:
        for cluster in config_file['clusters']:
            provider = network_map[cluster["vpc"]]
            if provider == "gcp":
                gcp.create_re_cluster(**cluster)
            elif provider == "aws":
                aws.create_re_cluster(**cluster)
            

if "name" not in os.environ:
    print("Usage: name=xxxx terraformpy where xxxx is the name of this deployment.  used to maintain isolation between deployments")
    exit(1)

f = open("config.yaml", "r")
config_file = yaml.load(f, Loader=yaml.FullLoader)
generate(config_file)
