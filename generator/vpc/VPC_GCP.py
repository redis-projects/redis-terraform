#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import itertools
import logging
from generator.vpc.Cloud_Provider_VPC_VNET import Cloud_Provider_VPC_VNET
from terraformpy import Module, Provider, Data, Output
from terraformpy.helpers import relative_file
from typing import List

class VPC_GCP(Cloud_Provider_VPC_VNET):

    def create_network(self) -> int:
        from generator.generator import deployment_name, vpc
        vpc_request_list = [f'${{module.network-{s}.vpc}}' for s in self._peer_request_list]
        vpc_accept_list  = [f'${{module.network-{s}.vpc}}' for s in self._peer_accept_list]
        cidr_list = [vpc[cidr].get_public_cidr() for cidr in self._peer_request_list]
        cidr_list = cidr_list + [vpc[cidr].get_private_cidr() for cidr in self._peer_request_list]
        cidr_list = cidr_list + [vpc[cidr].get_public_cidr() for cidr in self._peer_accept_list]
        cidr_list = cidr_list + [vpc[cidr].get_private_cidr() for cidr in self._peer_accept_list]

        Module(f"network-{self._name}", 
            source                  = f"./modules/{self._provider}/network",
            name                    = f"{deployment_name()}-{self._name}",
            gce_public_subnet_cidr  = self._public_cidr,
            region                  = self._region,
            providers               = {"google": f"google.{self._name}"},
            vpc_request_list        = vpc_request_list,
            vpc_accept_list         = vpc_accept_list,
            cidr_list               = cidr_list,
            gce_private_subnet_cidr = self._private_cidr)

    def create_bastion(self) -> int:
        from generator.generator import deployment_name, vpc
        Module(f"bastion-{self._name}",
            source                  = f"./modules/{self._provider}/bastion",
            name                    = f"{deployment_name()}-{self._name}",
            gce_public_subnet_cidr  = self._public_cidr,
            gce_private_subnet_cidr = self._private_cidr,
            region                  = self._region,
            subnet                  = f'${{module.network-{self._name}.public-subnet-name}}',
            os                      = self._bastion_machine_image,
            boot_disk_size          = self._boot_disk_size,
            bastion_machine_type    = self._bastion_machine_type,
            gce_ssh_user            = self._redis_user,
            gce_ssh_pub_key_file    = self._ssh_public_key,
            active_active_script    = '${data.template_file.aa_db}',
            providers               = {"google": f"google.{self._name}"},
            zone                    = self._bastion_zone
        )

        Output(f"gcp-bastion-{self._name}-ip-output",
            value = f"${{module.bastion-{self._name}.bastion-public-ip}}")

    def create_re_ui(self) -> int:
        deployment_name = os.getenv('name')
        Module(f"re-ui-{self._name}",
            source    = f"./modules/{self._provider}/re-ui",
            name      = f'{deployment_name}-{self._name}',
            instances = f'${{module.re-{self._name}.re-nodes.*.name}}',
            providers = {"google": f"google.{self._name}"},
            zones     = f'${{module.re-{self._name}.re-nodes.*.zone}}'
        )

        Output(f"gcp-re-ui-{self._name}-ip-output",
            value=f'${{module.re-ui-{self._name}.ui-ip.address}}')
        return(0)

    def VPC_GCP(self):
        pass

    def getProvider(self) -> str:
        return self._provider

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._bastion_machine_image : str = "rhel-7-v20210721"
        self._bastion_machine_type : str = "n1-standard-1"
        self._bastion_zone : str = "us-central1-b"
        self._name : str = None
        self._private_cidr : str = "10.0.2.0/16"
        self._project : str = "redislabs-sa-training-services"
        self._provider : str = "gcp"
        self._public_cidr : str = "10.0.1.0/24"
        self._region : str = "us-central1"
        self._worker_machine_image : str = "rhel-7-v20210721"
        self._redis_user = 'redislabs'
        self._ssh_public_key = '~/.ssh/id_rsa.pub'
        self._expose_ui = False
        self._peer_accept_list = []
        self._peer_request_list = []
        self._vpc_accept_list = []
        self._vpc_request_list = []
        self._vpn_accept_list = []
        self._vpn_request_list = []
        self._boot_disk_size = 50
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "bastion_machine_image": self._bastion_machine_image = value
            elif key == "bastion_machine_type": self._bastion_machine_type = value
            elif key == "bastion_zone": self._bastion_zone = value
            elif key == "name": self._name = value
            elif key == "private_cidr": self._private_cidr = value
            elif key == "project": self._project =value
            elif key == "public_cidr": self._public_cidr = value
            elif key == "provider": self._provider = value
            elif key == "region": self._region = value
            elif key == "worker_machine_image": self._worker_machine_image = value
            elif key == "expose_ui": self._expose_ui =value
            elif key == "peer_with": pass # ignore this key, will be traversed later
            else:
                logging.warn(f"Key {key} is being ignored ")

        Provider("google", project=self._project, region=self._region,
             credentials=relative_file("../../terraform_account.json"), alias=self._name)
        Provider("google-beta", project=self._project, region=self._region,
             credentials=relative_file("../../terraform_account.json"), alias=self._name)

