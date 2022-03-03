#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import itertools
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY
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
        vpn_list = sorted(self._vpn_set)
        private_subnet_list = []
        for peer in vpn_list:
            if type(vpc[peer].get_private_cidr()) is dict: #AWS
                for zone,cidr in vpc[peer].get_private_cidr().items():
                    private_subnet_list.append(cidr)
            else: #GCP and/or Azure
                private_subnet_list.append(vpc[peer].get_private_cidr())
        aws_vpns = [s for s in self._vpns if type(s["cidr"]) is dict]
        for vpn in aws_vpns:
            vpn['cidr_list'] = []
            for zone,cidr in vpn['cidr'].items():
                vpn['cidr_list'].append(cidr)

        Module(f"network-{self._name}", 
            source                  = f"./modules/{self._provider}/network",
            name                    = f"{deployment_name()}-{self._name}",
            vpc_name                = f"{self._name}",
            resource_name           = self._resource_name,
            resource_tags           = self._global_config["resource_tags"],
            gce_public_subnet_cidr  = self._public_cidr,
            ui_cidr                 = self._ui_cidr,
            region                  = self._region,
            providers               = {"google": f"google.{self._name}"},
            vpc_request_list        = vpc_request_list,
            vpc_accept_list         = vpc_accept_list,
            cidr_list               = cidr_list,
            gce_private_subnet_cidr = self._private_cidr,
            vpn_list                = vpn_list,
            gcp_azure_vpns          = [s for s in self._vpns if type(s["cidr"]) is not dict],
            aws_vpns                = aws_vpns,
            private_subnet_list     = private_subnet_list
            )

    def create_bastion(self) -> int:
        from generator.generator import deployment_name, vpc
        Module(f"bastion-{self._name}",
            source                  = f"./modules/{self._provider}/bastion",
            name                    = f"{deployment_name()}-{self._name}",
            resource_tags           = self._global_config["resource_tags"],
            gce_public_subnet_cidr  = self._public_cidr,
            gce_private_subnet_cidr = self._private_cidr,
            region                  = self._region,
            subnet                  = f'${{module.network-{self._name}.public-subnet-name}}',
            os                      = self._bastion_machine_image,
            boot_disk_size          = self._boot_disk_size,
            bastion_machine_type    = self._bastion_machine_type,
            gce_ssh_user            = self._redis_user,
            gce_ssh_pub_key_file    = self._ssh_public_key,
            providers               = {"google": f"google.{self._name}"},
            zone                    = self._bastion_zone
        )

        Output(f"GCP-bastion-{self._name}-ip-output",
            value = f"${{module.bastion-{self._name}.bastion-public-ip}}")

    def create_re_ui(self) -> int:
        deployment_name = os.getenv('name')
        Module(f"re-ui-{self._name}",
            source        = f"./modules/{self._provider}/re-ui",
            name          = f'{deployment_name}-{self._name}',
            resource_tags = self._global_config["resource_tags"],
            instances     = f'${{module.re-{self._name}.re-nodes.*.name}}',
            ui_subnet     = f'${{module.network-{self._name}.ui-subnet}}',
            providers     = {"google": f"google.{self._name}"},
            zones         = f'${{module.re-{self._name}.re-nodes.*.zone}}'
        )

        Output(f"GCP-re-ui-{self._name}-ip-output",
            value=f'${{module.re-ui-{self._name}.ui-ip.address}}')
        return(0)

    def VPC_GCP(self):
        pass

    def getProvider(self) -> str:
        return self._provider

    def __init__(self, **kwargs):
        from generator.generator import deployment_name
        super().__init__(**kwargs)
        self._bastion_machine_image : str = "rhel-7-v20210721"
        self._bastion_machine_type : str = "n1-standard-1"
        self._bastion_zone : str = "us-central1-b"
        self._name : str = None
        self._resource_name : str = None
        self._private_cidr : str = "10.0.2.0/16"
        self._project : str = "redislabs-sa-training-services"
        self._provider : str = "gcp"
        self._public_cidr : str = "10.0.1.0/24"
        self._lb_cidr = {}
        self._ui_cidr = ""
        self._region : str = "us-central1"
        self._worker_machine_image : str = "rhel-7-v20210721"
        self._redis_user = SSH_USER
        self._ssh_public_key = SSH_PUBLIC_KEY
        self._expose_ui = False
        self._peer_accept_list = []
        self._peer_request_list = []
        self._vpc_accept_list = []
        self._vpc_request_list = []
        self._vpn_set = set()
        self._vpns = []
        self._boot_disk_size = 50
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "bastion_machine_image": self._bastion_machine_image = value
            elif key == "bastion_machine_type": self._bastion_machine_type = value
            elif key == "bastion_zone": self._bastion_zone = value
            elif key == "name": self._name = value
            elif key == "resource_name": self._resource_name = value
            elif key == "private_cidr": self._private_cidr = value
            elif key == "project": self._project =value
            elif key == "public_cidr": self._public_cidr = value
            elif key == "ui_cidr": self._ui_cidr = value
            elif key == "lb_cidr": self._lb_cidr = value
            elif key == "provider": self._provider = value
            elif key == "region": self._region = value
            elif key == "worker_machine_image": self._worker_machine_image = value
            elif key == "expose_ui": self._expose_ui =value
            elif key == "peer_with": pass # ignore this key, will be traversed later
            else:
                logging.warn(f"Key {key} is being ignored ")

        if self._resource_name is None:
            self._resource_name = f'{deployment_name()}-{self._name}-vpc'

        Provider("google", project=self._project, region=self._region,
             credentials=relative_file("../../terraform_account.json"), alias=self._name)
        Provider("google-beta", project=self._project, region=self._region,
             credentials=relative_file("../../terraform_account.json"), alias=self._name)

