#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import logging
from generator import SSH_USER, SSH_PRIVATE_KEY
from terraformpy import Module, Provider, Data, Output
from typing import List

class Service(object):
    def provision_docker(self):
        if self._docker_provisioned == False:
            from generator.generator import servicenodes
            Module(f"docker-provisioner-{self._servicenode}",
                depends_on           = [f"module.servicenodes-{self._servicenode}"],
                source               = "./modules/docker/create",
                ssh_user             = self._ssh_user,
                ssh_private_key_file = self._ssh_private_key_file,
                servicenodes_private_ips         = f"${{module.servicenodes-{self._servicenode}.servicenodes_private_ip}}",
                bastion_host         = f"${{module.bastion-{servicenodes[self._servicenode].get_vpc()}.bastion-public-ip}}"
            )
        self._docker_provisioned = True

    def create_docker_service(self):
        from generator.generator import servicenodes
        Module(f"docker-service-{self._servicenode}-{self._name}",
            source               = "./modules/docker/services",
            depends_on           = [f"module.docker-provisioner-{self._servicenode}"],
            ssh_user             = self._ssh_user,
            contents             = self._contents,
            start_script         = "start.sh",
            ssh_private_key_file = self._ssh_private_key_file,
            servicenodes_private_ips         = f"${{module.servicenodes-{self._servicenode}.servicenodes_private_ip}}",
            bastion_host         = f"${{module.bastion-{servicenodes[self._servicenode].get_vpc()}.bastion-public-ip}}"
        )

    def __init__(self, **kwargs):
        self._name : str = None
        self._type : str = None
        self._contents : str = None
        self._servicenode : str = None
        self._docker_provisioned = False
        self._ssh_user = SSH_USER
        self._ssh_private_key_file = SSH_PRIVATE_KEY
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "name": self._name = value
            elif key == "type": self._type = value
            elif key == "contents": self._contents = value
            elif key == "servicenode": self._servicenode = value
            elif key == "ssh_user": self._ssh_user = value
            elif key == "ssh_private_key_file": self._ssh_private_key_file = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")

