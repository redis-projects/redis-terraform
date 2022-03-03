#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY, SSH_PRIVATE_KEY
from generator.cluster.Cluster import Cluster
from terraformpy.helpers import relative_file
from terraformpy import Module, Provider, Data, Output
from typing import List

class Cluster_AWS(Cluster):
    def create_data_objects(self):

        Data("template_file", f"inventory-{self._vpc}",
            template=relative_file("../../templates/inventory.tpl"),
            vars={
                'ip_addrs': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.private_ip)}}",
                'rack_ids': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.availability_zone)}}" if self._rack_aware else ""
            }
        )

        Data("template_file", f"extra_vars-{self._vpc}",
            template = relative_file("../../templates/extra-vars.tpl"),
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
        Module(f"re-{self._vpc}", 
            source          = f"./modules/{self._provider}/re",
            name            = f"{os.getenv('name')}-{self._vpc}",
            vpc             = f'${{module.network-{self._vpc}.vpc}}',
            resource_tags   = self._global_config["resource_tags"],
            worker_count    = self._worker_count,
            instance_type   = self._machine_type,
            ami             = self._machine_image,
            security_groups = f"${{module.network-{self._vpc}.private-security-groups}}",
            redis_user      = self._redis_user,
            ssh_public_key  = self._ssh_public_key,
            ssh_key_name    = f"${{module.keypair-{self._vpc}.key-name}}",
            providers       = {"aws": f"aws.{self._vpc}"},
            zones           = self._zones,
            subnet          = f"${{module.network-{self._vpc}.private-subnet}}",
            lb_subnet       = f"${{module.network-{self._vpc}.lb-subnet}}"
        )
        
        self.create_data_objects()

    def __init__(self, **kwargs):
        from generator.generator import vpc
        super().__init__()
        self._name : str = None
        self._vpc : str = None
        self._worker_count : int = 3
        self._expose_ui : bool = True
        self._rack_aware : bool = False
        self._redis_distro : str = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.6/redislabs-6.0.6-39-rhel7-x86_64.tar"
        self._zones = None
        self._machine_image = None
        self._machine_type = None
        self._redis_user = SSH_USER
        self._ssh_public_key = SSH_PUBLIC_KEY
        self._ssh_private_key =  SSH_PRIVATE_KEY
        self._redis_cluster_name = 'dtest.rlabs.org'
        self._redis_user_name =  'admin@admin.com'
        self._redis_pwd = 'admin'
        self._redis_email_from = 'admin@domain.tld'
        self._redis_smtp_host =  'smtp.domain.tld'     
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))
        for key, value in kwargs.items():
            if key == "vpc": self._vpc = value
            elif key == "name": self._name = value
            elif key == "worker_count": self._worker_count = value
            elif key == "expose_ui": 
                self._expose_ui = value
                vpc[self._vpc].set_ui(value)
            elif key == "rack_aware": self._rack_aware = value
            elif key == "redis_distro": self._redis_distro = value
            elif key == "zones": self._zones = value
            elif key == "machine_image": self._machine_image = value
            elif key == "machine_type": self._machine_type = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")
        
        self._provider = vpc[self._vpc].get_provider()
        self._region = vpc[self._vpc].get_region()
        self._resource_group = vpc[self._vpc].get_resource_group()
        self._boot_disk_size = 50


        

