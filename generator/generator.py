from terraformpy import Module, Provider, Data
from terraformpy.helpers import relative_file
import sys
from providers import aws, gcp, azure, REGION, ZONE, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, DEPLOYMENT_NAME

def generate(config_file):
    network_map = {}
    aws_cidr_map = {}
    gcp_cidr_map = {}
    region_map = {}
    fqdn_map = {}
    peer_request_map = {}
    peer_accept_map = {}
    network_names = {}
    rg_map = {}
    diff_providers = False
    last_provider = None

    if 'nameservers' in config_file:
        for nameserver in config_file['nameservers']:
            if "domain" not in nameserver or nameserver["domain"] is None:
                raise Exception ("Please supply domain for all nameservers")
            fqdn_map[nameserver["vpc"]] = "%s-%s.%s" % (DEPLOYMENT_NAME, nameserver["vpc"], nameserver["domain"])
            nameserver["cluster_fqdn"] = fqdn_map[nameserver["vpc"]]

    if 'networks' in config_file:
        for network in config_file['networks']:
            if "provider" not in network:
                raise Exception("ERROR: a provider must be specified for each network (google or aws)")
            provider = network["provider"]
            if not last_provider:
                last_provider = provider
            if last_provider != provider:
                diff_providers = True
            network_map[network["name"]] = provider
            if "resource_group" in network and provider == "azure":
                rg_map[network["name"]] = network['resource_group']
            if "peer_with" in network:
                for vpc_peer in network['peer_with']:
                    if  not next((item  for item in config_file['networks']  if item['name'] == vpc_peer), False):
                        raise Exception(f'ERROR: Requested peering vpc {vpc_peer} not found in config file')
                    vpc_provider = next(item['provider']  for item in config_file['networks']  if item['name'] == vpc_peer)
                    if  provider != vpc_provider:
                        raise Exception(f'ERROR: Peering network {vpc_peer} uses different provider ({vpc_provider}) than requester vpc ({provider})')
                    if network['name'] not in peer_request_map:
                        peer_request_map[network['name']] = []
                    if vpc_peer not in peer_accept_map:
                        peer_accept_map[vpc_peer] = []
                    peer_request_map[network['name']].append(vpc_peer)
                    peer_accept_map[vpc_peer].append(network["name"])
            if  provider == 'aws': aws_cidr_map[network["name"]] = network['vpc_cidr']
            if  provider == 'gcp': gcp_cidr_map[network["name"]] = [network['public_cidr'], network['private_cidr']]
            region_map[network["name"]] = network['region']
            network_names[network["name"]] = provider
        if not diff_providers or 'nameservers' not in config_file:
            network_names = {}

        clusters = [(cl_dict['vpc'],cl_dict['expose_ui']) for cl_dict in config_file['clusters']]
        for network in config_file['networks']:
            provider = network.pop('provider', "gcp")
            network.pop('peer_with','default')
            network["other_nets"] = network_names
            network["fqdn_map"] = fqdn_map
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
            elif provider == "azure":
                for clu in clusters:
                    if clu[0] == network["name"]:
                        expose_ui = clu[1]
                network.update(expose_ui = expose_ui)
                azure.create_network(**network)
            else: 
                raise Exception("unsupported provider {}".format(provider))
    if 'clusters' in config_file:
        for cluster in config_file['clusters']:
            provider = network_map[cluster["vpc"]]
            if provider == "gcp":
                gcp.create_re_cluster(**cluster)
            elif provider == "aws":
                aws.create_re_cluster(**cluster)
            elif provider == "azure":
                cluster.update(region_map = region_map)
                cluster.update(rg_map = rg_map)
                azure.create_re_cluster(**cluster)

    if 'nameservers' in config_file:
        for nameserver in config_file['nameservers']:
            provider = nameserver.pop('provider', network_map[nameserver["vpc"]])
            nameserver.pop('domain')
            if provider == "gcp":
                gcp.create_ns_records(**nameserver)
            elif provider == "aws":
                aws.create_ns_records(**nameserver)
            elif provider == "azure":
                nameserver.update(rg_map = rg_map)
                azure.create_ns_records(**nameserver)
            else: 
                raise Exception("unsupported provider in nameservers section {}".format(provider))
