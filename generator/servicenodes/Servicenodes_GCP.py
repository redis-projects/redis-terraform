#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY, SSH_PRIVATE_KEY
from generator.servicenodes.Servicenodes import Servicenodes
from terraformpy import Module, Provider, Data, Output
from typing import List

class Servicenodes_GCP(Servicenodes):
    def create_servicenodes(self) -> int:
        Module(f"servicenodes-{self._vpc}",
            source                    = f"./modules/{self._provider}/servicenodes",
            name                      = f"{os.getenv('name')}-{self._vpc}",
            resource_tags             = self._global_config["resource_tags"],
            kube_worker_machine_count = self._count,
            kube_worker_machine_type  = self._machine_type,
            boot_disk_size            = self._boot_disk_size,
            kube_worker_machine_image = self._machine_image,
            subnet                    = f"${{module.network-{self._vpc}.private-subnet-name}}",
            gce_ssh_user              = self._redis_user,
            gce_ssh_pub_key_file      = self._ssh_public_key,
            providers                 = {"google": f"google.{self._vpc}"},
            zones                     = self._zones
        )
        
    def __init__(self, **kwargs):
        from generator.generator import vpc
        super().__init__()
        self._name : str = None
        self._vpc : str = None
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
        self._boot_disk_size = 50

        if self._name is None:
          assert("Each servicenodes block requires a unique name to be defined")


        

