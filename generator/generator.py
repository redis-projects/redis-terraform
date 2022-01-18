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
    # Disctionary for all services
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
                logging.error(f"network {network['name']} has an unsupported provider {network['provider']}")
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

    if 'services' in config_file:
        for svc in config_file['services']:
            if svc["vpc"] in service:
                service[svc["vpc"]].add(Service(**svc))
            else:
                service[svc["vpc"]] = [Service(**svc)]
            logging.debug(f"A new service for VPC/VNET {svc['vpc']} has been added with the arguments {svc}")

    if 'databases' in config_file:
        for re_db in config_file['databases']:
            service[svc["vpc"]] = Databases(**re_db)
            logging.debug(f"A new database for cluster(s) {database['clusters']} has been added with the arguments {re_db}")

    # By now we have thefile mapped and crated all objects.
    # Next step is o model the network relationship (VPC Peering/VPN).
    for network in config_file['networks']:
        if "peer_with" in network:
            vpc[network['name']].add_peers(network['peer_with'])
    # Create the VPCs/VNETs and the UI Loadbalancer
    for name in vpc :
        vpc[name].create_network()
        vpc[name].create_re_ui()
    # Create the Bastion hosts
    for name in vpc :
        vpc[name].create_bastion()
    # Create the nameserver entries
    for ns_data in ns_entry :
        ns_entry[ns_data].create_ns_records()
    # Create the Clusters
    for cluster in re_cluster :
        re_cluster[cluster].create_re_cluster()
    # Create Services
    for vpc in service :
        service[vpc][0].provision_docker()
        for svc in service[vpc]:
            svc.create_docker_service()

def deployment_name():
    return(os.getenv('name'))
