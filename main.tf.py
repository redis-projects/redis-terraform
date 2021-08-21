from terraformpy import Module, Provider, Data
from terraformpy.helpers import relative_file
import os
import yaml
import sys
from providers import aws, gcp, REGION, ZONE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, DEPLOYMENT_NAME

gcp_provider = Provider("google", project="redislabs-sa-training-services", region=REGION, zone=ZONE, credentials=relative_file("./terraform_account.json"))
aws_provider = Provider("aws", region=AWS_REGION, access_key=AWS_ACCESS_KEY_ID, secret_key=AWS_SECRET_ACCESS_KEY)

#gcp_provider2 = Provider("google", project="redislabs-sa-training-services", region="us-east1", zone="us-east1-b", credentials=relative_file("./terraform_account.json"), alias="alternate")

random_id = Module("random_id", source="./modules/random_id") 

def generate(config_file):
    network_map = {}
    fqdn_map = {}

    if 'nameservers' in config_file:
        for nameserver in config_file['nameservers']:
            fqdn_map[nameserver["vpc"]] = "%s-%s.%s" % (DEPLOYMENT_NAME, nameserver["vpc"], nameserver["parent_zone"])
            nameserver["cluster_fqdn"] = fqdn_map[nameserver["vpc"]]

    if 'networks' in config_file:
        for network in config_file['networks']:
            provider = network.pop('provider', "gcp")
            network_map[network["name"]] = provider
            if network["name"] in fqdn_map:
                network.update(redis_cluster_name = fqdn_map[network["name"]])
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

    if 'nameservers' in config_file:
        for nameserver in config_file['nameservers']:
            provider = nameserver.pop('provider', "gcp")
            if provider == "gcp":
                gcp.create_ns_records(**nameserver)
            elif provider == "aws":
                aws.create_ns_records(**nameserver)
            else: 
                print("unsupported provider n nameservers section {}".format(provider))

if "name" not in os.environ:
    print("Usage: name=xxxx terraformpy where xxxx is the name of this deployment.  used to maintain isolation between deployments")
    exit(1)

config_file_name = os.getenv("config","config.yaml")

f = open(config_file_name, "r")
config_file = yaml.load(f, Loader=yaml.FullLoader)
generate(config_file)
