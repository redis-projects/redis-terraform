#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
import generator.generator
import generator.Cloud_Provider_VPC_VNET
import generator.Databases
import generator.Host
from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
from typing import List

class Cluster(object):
    def set_cluster_name(self,cluster_name):
        self._redis_cluster_name = cluster_name

    def create_provisioner(self):
        other_nets = {}
        for vpc_iter in generator.generator.vpc:
            if vpc_iter != self._vpc and generator.generator.vpc[vpc_iter].get_provider() != self._provider:
               other_nets[vpc_iter] = generator.generator.vpc[vpc_iter].get_provider()

        fqdn_map = {}
        deployment_name = os.getenv('name')
        for ns_data in generator.generator.ns_entry:
            fqdn_map[ns_data] = f"{deployment_name}-{ns_data}.{generator.generator.ns_entry[ns_data].get_domain()}"

        Module(f"re-provisioner-{self._vpc}",
            source               = "./modules/ansible/re",
            ssh_user             = self._redis_user,
            inventory            = f'${{data.template_file.inventory-{self._vpc}}}',
            extra_vars           = f'${{data.template_file.extra_vars-{self._vpc}}}',
            ssh_private_key_file = self._ssh_private_key,
            host                 = f"${{module.bastion-{self._vpc}.bastion-public-ip}}",
            redis_distro         = self._redis_distro,
            cluster_fqdn         = [fqdn_map[vpc] for vpc in other_nets.keys() if vpc != self._vpc and other_nets[vpc] != self._provider],
            other_bastions       = [f'${{module.bastion-{vpc}.bastion-public-ip}}' for vpc in other_nets.keys()],
            other_ssh_users      = [ self._redis_user for vpc in other_nets.keys() ],
            ssh_keys             = [ self._ssh_private_key for vpc in other_nets.keys() ]
        )

    def create_data_objects(self):

        if self._provider == "azure":
            Data("template_file", f"inventory-{self._vpc}",
                template = relative_file("../templates/inventory.tpl"),
                vars = {
                    'ip_addrs': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.private_ip_address)}}",
                    'rack_ids': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.zone)}}" if self._rack_aware else ""
                }
            )
        elif self._provider == "aws":
            Data("template_file", f"inventory-{self._vpc}",
                template=relative_file("../templates/inventory.tpl"),
                vars={
                    'ip_addrs': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.private_ip)}}",
                    'rack_ids': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.availability_zone)}}" if self._rack_aware else ""
                }
            )
        elif self._provider == "gcp":
            Data("template_file", f"inventory-{self._vpc}",
                template=relative_file("../templates/inventory.tpl"),
                vars={
                    'ip_addrs': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.name)}}",
                    'rack_ids': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.zone)}}" if self._rack_aware else ""
                }
            )

        if self._provider != "aws":
            Data("template_file", "aa_db",
                template = relative_file("../templates/create_aa_db.tpl"),
                vars = {
                    'redis_user_name': self._redis_user_name,
                    'redis_pwd': self._redis_pwd,
                    'redis_cluster_name': self._redis_cluster_name,
                    'FQDN1': 'domain1.test.net',
                    'FQDN2': 'domain2.test.net'
                }
            )

        Data("template_file", f"extra_vars-{self._vpc}",
            template = relative_file("../templates/extra-vars.tpl"),
            vars = {
                'ansible_user': self._redis_user,
                'redis_cluster_name': self._redis_cluster_name,
                'redis_user_name': self._redis_user_name,
                'redis_pwd': self._redis_pwd,
                'redis_email_from': self._redis_email_from,
                'redis_smtp_host': self._redis_smtp_host
            }
        )

        self.create_provisioner()

    def create_re_cluster(self) -> int:
        
        if self._provider == 'aws':
            Module(f"re-{self._vpc}", 
                source          = f"./modules/{self._provider}/re",
                name            = f"{os.getenv('name')}-{self._vpc}",
                worker_count    = self._worker_count,
                instance_type   = self._machine_type,
                ami             = self._machine_image,
                security_groups = f"${{module.network-{self._vpc}.private-security-groups}}",
                redis_user      = self._redis_user,
                ssh_public_key  = self._ssh_public_key,
                ssh_key_name    = f"${{module.keypair-{self._vpc}.key-name}}",
                providers       = {"aws": f"aws.{self._vpc}"},
                zones           = self._zones,
                subnet          = f"${{module.network-{self._vpc}.private-subnet}}"
            )
        elif self._provider == 'azure':
            Module(f"re-{self._vpc}",
                source            = f"./modules/{self._provider}/re",
                name              = f"{os.getenv('name')}-{self._vpc}",
                machine_count     = self._worker_count,
                machine_type      = self._machine_type,
                os                = self._machine_image,
                private_subnet_id = f"${{module.network-{self._vpc}.private-subnet}}",
                private_secgroup  = f"${{module.network-{self._vpc}.private-security-groups}}",
                ssh_user          = self._redis_user,
                ssh_pub_key_file  = self._ssh_public_key,
                providers         = {"azurerm": f"azurerm.{self._vpc}"},
                zones             = self._zones,
                region            = self._region,
                resource_group    = self._resource_group
            )
        elif self._provider == 'gcp':
            Module(f"re-{self._vpc}",
                source                    = f"./modules/{self._provider}/re",
                name                      = f"{os.getenv('name')}-{self._vpc}",
                kube_worker_machine_count = self._worker_count,
                kube_worker_machine_type  = self._machine_type,
                boot_disk_size            = self._boot_disk_size,
                kube_worker_machine_image = self._machine_image,
                subnet                    = f"${{module.network-{self._vpc}.private-subnet-name}}",
                gce_ssh_user              = self._redis_user,
                gce_ssh_pub_key_file      = self._ssh_public_key,
                providers                 = {"google": f"google.{self._vpc}"},
                zones                     = self._zones
            )
        
        self.create_data_objects()

    def __init__(self, **kwargs):
        self._vpc : str = None
        self._worker_count : int = 3
        self._expose_ui : bool = True
        self._rack_aware : bool = False
        self._redis_distro : str = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.6/redislabs-6.0.6-39-rhel7-x86_64.tar"
        self._zones = None
        self._machine_image = None
        self._machine_type = None
        self._redis_user = 'redislabs'
        self._ssh_public_key = '~/.ssh/id_rsa.pub'
        self._ssh_private_key =  '~/.ssh/id_rsa'
        self._redis_cluster_name = 'dtest.rlabs.org'
        self._redis_user_name =  'admin@admin.com'
        self._redis_pwd = 'admin'
        self._redis_email_from = 'admin@domain.tld'
        self._redis_smtp_host =  'smtp.domain.tld'     
        self._contains : generator.Cloud_Provider_VPC_VNET.Cloud_Provider_VPC_VNET = None
        """# @AssociationMultiplicity 1"""
        self._runs_on : generator.Databases.Databases = None
        """# @AssociationMultiplicity 1"""
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))
        for key, value in kwargs.items():
            if key == "vpc": self._vpc = value
            elif key == "worker_count": self._worker_count = value
            elif key == "expose_ui": self._expose_ui = value
            elif key == "rack_aware": self._rack_aware = value
            elif key == "redis_distro": self._redis_distro = value
            elif key == "zones": self._zones = value
            elif key == "machine_image": self._machine_image = value
            elif key == "machine_type": self._machine_type = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")
        
        self._provider = generator.generator.vpc[self._vpc].get_provider()
        self._region = generator.generator.vpc[self._vpc].get_region()
        self._resource_group = generator.generator.vpc[self._vpc].get_resource_group()
        self._boot_disk_size = 50


        

