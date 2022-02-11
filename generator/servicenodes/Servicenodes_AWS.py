#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY, SSH_PRIVATE_KEY
from generator.servicenodes.Servicenodes import Servicenodes
from terraformpy.helpers import relative_file
from terraformpy import Module, Provider, Data, Output
from typing import List

class Servicenodes_AWS(Servicenodes):
    def create_servicenodes(self) -> int:
        Module(f"servicenodes-{self._name}", 
            source          = f"./modules/{self._provider}/servicenodes",
            name            = f"{os.getenv('name')}-{self._vpc}",
            resource_tags   = self._global_config["resource_tags"],
            node_count      = self._count,
            instance_type   = self._machine_type,
            ami             = self._machine_image,
            security_groups = f"${{module.network-{self._vpc}.public-security-groups}}",
            redis_user      = self._redis_user,
            ssh_public_key  = self._ssh_public_key,
            ssh_key_name    = f"${{module.keypair-{self._vpc}.key-name}}",
            providers       = {"aws": f"aws.{self._vpc}"},
            zones           = self._zones,
            subnet          = f"${{module.network-{self._vpc}.public-subnet}}",
            depends_on      = [f"module.bastion-{self._vpc}"]
        )

        Output(f"AWS-servicenodes-{self._name}-private-ip-adresses",
            value=f"${{module.servicenodes-{self._name}.servicenodes_private_ip}}")
        Output(f"AWS-servicenodes-{self._name}-public-ip-adresses",
            value=f"${{module.servicenodes-{self._name}.servicenodes_public_ip}}")
        
    def __init__(self, **kwargs):
        from generator.generator import vpc
        super().__init__()
        self._vpc : str = None
        self._name : str = None
        self._count : int = 3
        self._zones = None
        self._machine_image = None
        self._machine_type = None
        self._redis_user = SSH_USER
        self._ssh_public_key = SSH_PUBLIC_KEY
        self._ssh_private_key =  SSH_PRIVATE_KEY
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))
        for key, value in kwargs.items():
            if key == "vpc": self._vpc = value
            elif key == "name": self._name = value
            elif key == "count": self._count = value
            elif key == "zones": self._zones = value
            elif key == "machine_image": self._machine_image = value
            elif key == "machine_type": self._machine_type = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")
        
        self._provider = vpc[self._vpc].get_provider()
        self._region = vpc[self._vpc].get_region()

        if self._name is None:
          assert("Each servicenodes block requires a unique name to be defined")
