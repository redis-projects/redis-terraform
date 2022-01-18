#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
from typing import List

class Cluster(object):
    def set_cluster_name(self,cluster_name):
        self._redis_cluster_name = cluster_name

    def get_provider(self):
        return(self._provider)
    
    def get_vpc(self):
        return(self._vpc)
    
    def get_name(self):
        return(self._name)

    def create_provisioner(self):
 
        Module(f"re-provisioner-{self._vpc}",
            source               = "./modules/ansible/re",
            ssh_user             = self._redis_user,
            inventory            = f'${{data.template_file.inventory-{self._vpc}}}',
            extra_vars           = f'${{data.template_file.extra_vars-{self._vpc}}}',
            ssh_private_key_file = self._ssh_private_key,
            host                 = f"${{module.bastion-{self._vpc}.bastion-public-ip}}",
            redis_distro         = self._redis_distro,
        )

    def __init__(self):
        from generator.generator import global_config
        self._global_config = {}
        if "resource_tags" in global_config:
            self._global_config["resource_tags"] = global_config["resource_tags"]
        else:
            self._global_config["resource_tags"] = {}
 


        

