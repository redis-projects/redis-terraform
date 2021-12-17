#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import logging
from terraformpy import Module, Provider, Data, Output
from typing import List

class Service(object):
    def provision_docker(self):
        if self._docker_provisioned == False:
            Module(f"docker-provisioner-{self._vpc}",
                depends_on           = [f"module.re-provisioner-{self._vpc}"],
                source               = "./modules/docker/create",
                ssh_user             = self._ssh_user,
                ssh_private_key_file = self._ssh_private_key_file,
                host                 = f"${{module.bastion-{self._vpc}.bastion-public-ip}}"
            )
        self._docker_provisioned = True

    def create_docker_service(self):
        Module(f"docker-service-{self._name}",
            source               = "./modules/docker/services",
            depends_on           = [f"module.docker-provisioner-{self._vpc}"],
            ssh_user             = self._ssh_user,
            contents             = self._contents,
            start_script         = "start.sh",
            ssh_private_key_file = self._ssh_private_key_file,
            host                 = f"${{module.bastion-{self._vpc}.bastion-public-ip}}"
        )

    def __init__(self, **kwargs):
        self._name : str = None
        self._type : str = None
        self._contents : str = None
        self._vpc : str = None
        self._docker_provisioned = False
        self._ssh_user = "redislabs"
        self._ssh_private_key_file = '~/.ssh/id_rsa'
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "name": self._name = value
            elif key == "type": self._type = value
            elif key == "contents": self._contents = value
            elif key == "vpc": self._vpc = value
            elif key == "ssh_user": self._ssh_user = value
            elif key == "ssh_private_key_file": self._ssh_private_key_file = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")

