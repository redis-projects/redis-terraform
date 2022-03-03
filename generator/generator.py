""" This file defines the generate function which parses the config file in a python dictionary form
"""
import sys
import os
import logging
from generator.vpc.VNET_Azure import VNET_Azure
from generator.vpc.VPC_GCP import VPC_GCP
from generator.vpc.VPC_AWS import VPC_AWS
from generator.cluster.Cluster_Azure import Cluster_Azure
from generator.cluster.Cluster_GCP import Cluster_GCP
from generator.cluster.Cluster_AWS import Cluster_AWS
from generator.servicenodes.Servicenodes_Azure import Servicenodes_Azure
from generator.servicenodes.Servicenodes_GCP import Servicenodes_GCP
from generator.servicenodes.Servicenodes_AWS import Servicenodes_AWS
from generator.nameserver.Nameserver_Entries import Nameserver_Entries
from generator.service.Service import Service
from generator.database.Databases import Databases
from terraformpy import Module

def generate(config_file):
    """ this generate function parses the config file and creates all objects """

    # Configure the Logging
    logging.basicConfig(level=logging.INFO)

    # Global settings in the config file
    global global_config
    global_config = {}
    # Dictionary of all VPCs and VNETs
    global vpc 
    vpc = {}
    # Disctionary for all redis clusters
    global re_cluster
    re_cluster = {}
    # Disctionary for all nameserver entries
    global ns_entry
    ns_entry = {}
    # Dictionary for Servicenodes
    global servicenodes
    servicenodes = {}
    # Dictionary for all services
    service = {}
    # Disctionary for all databases
    database = {}

    # Go through all top level nodes in the YAML file
    if 'global' in config_file:
        global_config = config_file["global"]
    if 'networks' in config_file:
        for network in config_file['networks']:
            if 'provider' not in network:
                vpc[network["name"]] = VPC_GCP(**network)
            elif network["provider"] == "aws":
                vpc[network["name"]] = VPC_AWS(**network)
            elif network["provider"] == "gcp":
                vpc[network["name"]] = VPC_GCP(**network)
            elif network["provider"] == "azure":
                vpc[network["name"]] = VNET_Azure(**network)
            else:
                raise Exception(f"network {network['name']} has an unsupported provider {network['provider']}")
            logging.debug(f"A new network vpc {network['name']} has been added with the arguments {network}")
    else:
        logging.error("No section called network in the config file, but this is a requirement")
        sys.exit(1)
   
    if 'nameservers' in config_file:
        for ns_data in config_file['nameservers']:
            ns_entry[f'{ns_data["cluster"]}-{ns_data["vpc"]}'] = Nameserver_Entries(**ns_data)
            logging.debug(f"A new nameserver entry for Cluster {ns_data['cluster']} in VPC/VNET {ns_data['vpc']} has been added with the arguments {ns_data}")
    
    if 'clusters' in config_file:
        for cluster in config_file['clusters']:
            provider = vpc[cluster["vpc"]].get_provider()
            if cluster["name"] in re_cluster:
                logging.error(f"Cluster name {cluster['name']} is not unique but this is a requirement")
                sys.exit(1)
            if provider == "aws":
                re_cluster[f'{cluster["name"]}'] = Cluster_AWS(**cluster)
            elif provider == "azure":
                re_cluster[f'{cluster["name"]}'] = Cluster_Azure(**cluster)
            elif provider == "gcp":
                re_cluster[f'{cluster["name"]}'] = Cluster_GCP(**cluster)
            logging.debug(f"A new cluster for VPC/VNET {cluster['vpc']} has been added with the arguments {cluster}")
    
    if 'servicenodes' in config_file:
        for sn in config_file['servicenodes']:
            provider = vpc[sn["vpc"]].get_provider()
            if provider == "aws":
                servicenodes[f'{sn["name"]}'] = Servicenodes_AWS(**sn)
            elif provider == "azure":
                servicenodes[f'{sn["name"]}'] = Servicenodes_Azure(**sn)
            elif provider == "gcp":
                servicenodes[f'{sn["name"]}'] = Servicenodes_GCP(**sn)
            logging.debug(f"A new Servicenodes entry named {sn['name']} has been added with the arguments {sn}")

    if 'services' in config_file:
        for svc in config_file['services']:
            if svc["servicenode"] in service:
                service[svc["servicenode"]].append(Service(**svc))
            else:
                service[svc["servicenode"]] = [Service(**svc)]
            logging.debug(f"A new service for VPC/VNET {svc['servicenode']} has been added with the arguments {svc}")

    if 'databases' in config_file:
        for re_db in config_file['databases']:
            service[svc["vpc"]] = Databases(**re_db) #TODO this looks wrong
            logging.debug(f"A new database for cluster(s) {database['clusters']} has been added with the arguments {re_db}")

    # By now we have the file mapped and crated all objects.
    # Next step is o model the network relationship (VPC Peering/VPN).
    for network in config_file['networks']:
        if "peer_with" in network:
            vpc[network['name']].add_peers(network['peer_with'])
    # create all VPN secret keys, CIDRs and names for VPN peers
    for network in config_file['networks']:
        for vpn_peer in vpc[network['name']].get_vpn_peers():
            secret_key = vpc[network['name']].create_vpn_secrets()
            if vpn_peer not in vpc[network['name']].get_vpns():
                vpc[network['name']].set_vpns(vpn_peer,vpc[vpn_peer].get_private_cidr(),secret_key,f'${{module.network-{vpn_peer}.vpn_external_ip}}')
            if  network['name'] not in vpc[vpn_peer].get_vpns():
                vpc[vpn_peer].set_vpns(network['name'],vpc[network['name']].get_private_cidr(),secret_key,f'${{module.network-{network["name"]}.vpn_external_ip}}')
    # Create the VPCs/VNETs and the UI Loadbalancer
    for name in vpc :
        vpc[name].create_network()
        vpc[name].expose_re_ui()
    # Create the Bastion hosts
    for name in vpc :
        vpc[name].create_bastion()
    # Create the nameserver entries
    for ns_data in ns_entry :
        ns_entry[ns_data].create_ns_records()
    # Create the Clusters
    for cluster in re_cluster :
        re_cluster[cluster].create_re_cluster()
    # Create the Service nodes
    for sn in servicenodes :
        servicenodes[sn].create_servicenodes()
    # Create Services
    for vpc in service :
        service[vpc][0].provision_docker()
        for svc in service[vpc]:
            svc.create_docker_service()

def deployment_name():
    return(os.getenv('name'))
