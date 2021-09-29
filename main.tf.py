from terraformpy import Module, Provider, Data
from terraformpy.helpers import relative_file
import os
import yaml
import sys
from providers import aws, gcp, REGION, ZONE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, DEPLOYMENT_NAME

#gcp_provider = Provider("google", project="redislabs-sa-training-services", region=REGION, zone=ZONE, credentials=relative_file("./terraform_account.json"))

random_id = Module("random_id", source="./modules/random_id") 

def generate(config_file):
    network_map = {}
    aws_cidr_map = {}
    gcp_cidr_map = {}
    region_map = {}
    fqdn_map = {}
    peer_request_map = {}
    peer_accept_map = {}

    if 'nameservers' in config_file:
        for nameserver in config_file['nameservers']:
            assert nameserver["domain"] is not None, "Please supply domain for all nameservers"
            fqdn_map[nameserver["vpc"]] = "%s-%s.%s" % (DEPLOYMENT_NAME, nameserver["vpc"], nameserver["domain"])
            nameserver["cluster_fqdn"] = fqdn_map[nameserver["vpc"]]

    if 'networks' in config_file:
        for network in config_file['networks']:
            if "provider" not in network:
                print("ERROR: a provider must be specified for each network (google or aws)")
                exit(1)
            provider = network["provider"]
            network_map[network["name"]] = provider
            if "peer_with" in network:
                for vpc_peer in network['peer_with']:
                    if  not next((item  for item in config_file['networks']  if item['name'] == vpc_peer), False):
                        print(f'ERROR: Requested peering vpc {vpc_peer} not found in config file')
                        exit(1)
                    vpc_provider = next(item['provider']  for item in config_file['networks']  if item['name'] == vpc_peer)
                    if  provider != vpc_provider:
                        print(f'ERROR: Peering network {vpc_peer} uses different provider ({vpc_provider}) than requester vpc ({provider})')
                        exit(1)
                    if network['name'] not in peer_request_map:
                        peer_request_map[network['name']] = []
                    if vpc_peer not in peer_accept_map:
                        peer_accept_map[vpc_peer] = []
                    peer_request_map[network['name']].append(vpc_peer)
                    peer_accept_map[vpc_peer].append(network["name"])
            if  provider == 'aws': aws_cidr_map[network["name"]] = network['vpc_cidr']
            if  provider == 'gcp': gcp_cidr_map[network["name"]] = [network['public_cidr'], network['private_cidr']]
            region_map[network["name"]] = network['region']

        for network in config_file['networks']:
            provider = network.pop('provider', "gcp")
            network.pop('peer_with','default')
            if network["name"] in peer_request_map:
                network.update(peer_request_list = peer_request_map[network["name"]])
            if network["name"] in peer_accept_map:
                network.update(peer_accept_list = peer_accept_map[network["name"]])
            if network["name"] in fqdn_map:
                network.update(redis_cluster_name = fqdn_map[network["name"]])
            if provider == "gcp":
                network.update(cidr_map = gcp_cidr_map)
                gcp.create_network(**network)
            elif provider == "aws":
                network.update(cidr_map = aws_cidr_map)
                network.update(region_map = region_map)
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
            provider = nameserver.pop('provider', network_map[nameserver["vpc"]])
            nameserver.pop('domain')
            if provider == "gcp":
                gcp.create_ns_records(**nameserver)
            elif provider == "aws":
                aws.create_ns_records(**nameserver)
            else: 
                print("unsupported provider in nameservers section {}".format(provider))

if "name" not in os.environ:
    print("Usage: name=xxxx terraformpy where xxxx is the name of this deployment.  used to maintain isolation between deployments")
    exit(1)

config_file_name = os.getenv("config","config.yaml")

f = open(config_file_name, "r")
config_file = yaml.load(f, Loader=yaml.FullLoader)
generate(config_file)
