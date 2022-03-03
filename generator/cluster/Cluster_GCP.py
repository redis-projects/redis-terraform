#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY, SSH_PRIVATE_KEY
from generator.cluster.Cluster import Cluster
from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
from typing import List

class Cluster_GCP(Cluster):
    def create_data_objects(self):

        Data("template_file", f"inventory-{self._vpc}",
            template=relative_file("../../templates/inventory.tpl"),
            vars={
                'ip_addrs': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.name)}}",
                'rack_ids': f"${{join(\",\", module.re-{self._vpc}.re-nodes.*.zone)}}" if self._rack_aware else ""
            }
        )

        Data("template_file", "aa_db",
            template = relative_file("../../templates/create_aa_db.tpl"),
            vars = {
                'redis_user_name': self._redis_user_name,
                'redis_pwd': self._redis_pwd,
                'redis_cluster_name': self._redis_cluster_name,
                'FQDN1': 'domain1.test.net',
                'FQDN2': 'domain2.test.net'
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
            source                    = f"./modules/{self._provider}/re",
            name                      = f"{os.getenv('name')}-{self._vpc}",
            resource_tags             = self._global_config["resource_tags"],
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
        from generator.generator import vpc
        super().__init__()
        self._vpc : str = None
        self._name : str = None
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


        

