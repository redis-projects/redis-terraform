#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import itertools
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY
from generator.vpc.Cloud_Provider_VPC_VNET import Cloud_Provider_VPC_VNET
from terraformpy import Module, Provider, Output
from typing import List

class VPC_AWS(Cloud_Provider_VPC_VNET):

    def create_network(self) -> int:
        from generator.generator import vpc, deployment_name
        region_map = {}
        cidr_map = {}
        vpn_list = sorted(self._vpn_set)
        cidr_map[self._name] = self._vpc_cidr
        for vpc_iter in itertools.chain(self._peer_accept_list, self._peer_request_list):
            cidr_map[vpc_iter] = vpc[vpc_iter].get_vpc_cidr()
        for vpc_iter in vpc:
            region_map[vpc_iter] = vpc[vpc_iter].get_region()

        vpc_request_list    = [f'${{module.network-{s}.vpc}}' for s in self._peer_request_list]
        vpc_accept_list     = [f'${{module.network-{s}.vpc}}' for s in self._peer_accept_list]
        vpc_conn_index      = [f'${{module.network-{s}.peering-request-ids["{self._name}"]}}' for s in self._peer_accept_list]
        private_subnet_list = [f'${{module.network-{s}.private_subnet_address_prefix}}' for s in vpn_list]
        aws_vpns = [s for s in self._vpns if type(s["cidr"]) is dict]
        for vpn in aws_vpns:
            vpn['cidr_list'] = []
            for zone,cidr in vpn['cidr'].items():
                vpn['cidr_list'].append(cidr)


        Module(f"network-{self._name}", 
            source              = f"./modules/{self._provider}/network",
            name                = f"{deployment_name()}-{self._name}",
            resource_name       = self._resource_name,
            resource_tags       = self._global_config["resource_tags"],
            vpc_name            = self._name,
            vpc_cidr            = self._vpc_cidr,
            availability_zone   = self._bastion_zone,
            public_subnet_cidr  = self._public_cidr,
            lb_subnet_cidr      = self._lb_cidr,
            ui_cidr             = self._ui_cidr,
            providers           = {"aws": f"aws.{self._name}"},
            peer_request_list   = self._peer_request_list,
            peer_accept_list    = self._peer_accept_list,
            vpc_request_list    = vpc_request_list,
            vpc_accept_list     = vpc_accept_list,
            vpn_list            = vpn_list,
            gcp_azure_vpns      = [s for s in self._vpns if type(s["cidr"]) is not dict],
            region_map          = region_map,
            cidr_map            = cidr_map,
            vpc_conn_index      = vpc_conn_index,
            private_subnet_list = private_subnet_list,
            private_subnet_cidr = self._private_cidr)
        return(0)

    def create_bastion(self) -> int:
        from generator.generator import vpc, deployment_name
        Module(f"keypair-{self._name}",
            name           = f"{deployment_name()}-{self._name}-keypair",
            source         = f"./modules/{self._provider}/keypair",
            ssh_public_key = self._ssh_public_key,
            resource_tags  = self._global_config["resource_tags"],
            providers      = {"aws": f"aws.{self._name}"},
        )

        # The public_cidr disctionary becomes an array in Terraform keys()/values() 
        # where the sort order is by key
        bastion_zone_index = sorted(self._public_cidr).index(self._bastion_zone)
        Module(f"bastion-{self._name}",
            source            = f"./modules/{self._provider}/bastion",
            vpc               = f'${{module.network-{self._name}.vpc}}',
            name              = f"{deployment_name()}-{self._name}",
            resource_tags     = self._global_config["resource_tags"],
            subnet            = f'${{module.network-{self._name}.public-subnet[{bastion_zone_index}].id}}',
            ami               = self._bastion_machine_image,
            instance_type     = self._bastion_machine_type,
            redis_user        = self._redis_user,
            ssh_public_key    = self._ssh_public_key,
            ssh_key_name      = f'${{module.keypair-{self._name}.key-name}}',
            providers         = {"aws": f"aws.{self._name}"},
            security_groups   = f'${{module.network-{self._name}.public-security-groups}}',
            availability_zone = self._bastion_zone
        )

        Output(f"AWS-bastion-{self._name}-ip-output",
            value=f"${{module.bastion-{self._name}.bastion-public-ip}}")

    def create_re_ui(self) -> int:
        from generator.generator import vpc, deployment_name
        Module(f"re-ui-{self._name}",
            source         = f"./modules/{self._provider}/re-ui",
            name           = f'{deployment_name()}-{self._name}',
            vpc            = f'${{module.network-{self._name}.vpc}}',
            resource_tags  = self._global_config["resource_tags"],
            ips            = f'${{module.re-{self._name}.re-nodes.*.private_ip}}',
            subnets        = f'${{module.network-{self._name}.lb-subnet.*.id}}',
            ui_subnets     = f'${{module.network-{self._name}.ui-subnet.*.id}}',
            providers      = {"aws": f"aws.{self._name}"}
        )

        Output(f"AWS-re-ui-{self._name}-ip-output",
            value=f'${{module.re-ui-{self._name}.ui-ip}}')

    def VPC_AWS(self):
        pass

    def __init__(self, **kwargs):
        from generator.generator import deployment_name
        super().__init__(**kwargs)
        self._bastion_machine_image : str = "ami-0b1db37f0fa006678"
        self._bastion_machine_type : str = "t2.micro"
        self._bastion_zone : str = "us-east-1c"
        self._name : str = None
        self._resource_name : str = None
        self._provider : str = "aws"
        self._region : str = "us-east-1"
        self._vpc_cidr : str = "10.1.0.0/16"
        self._public_cidr = {}
        self._private_cidr = {}
        self._lb_cidr = {}
        self._ui_cidr = {}
        self._worker_machine_image : str = "ami-0b1db37f0fa006678"
        self._redis_user = SSH_USER
        self._ssh_public_key = SSH_PUBLIC_KEY
        self._expose_ui = True
        self._peer_accept_list = []
        self._peer_request_list = []
        self._vpc_accept_list = []
        self._vpc_request_list = []
        self._vpn_set = set()
        self._vpns = []

        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "bastion_machine_image": self._bastion_machine_image = value
            elif key == "bastion_machine_type": self._bastion_machine_type = value
            elif key == "bastion_zone": self._bastion_zone = value
            elif key == "name": self._name = value
            elif key == "resource_name": self._resource_name = value
            elif key == "private_cidr": self._private_cidr = value
            elif key == "public_cidr": self._public_cidr = value
            elif key == "lb_cidr": self._lb_cidr = value
            elif key == "ui_cidr": self._ui_cidr = value
            elif key == "provider": self._provider = value
            elif key == "region": self._region = value
            elif key == "vpc_cidr": self._vpc_cidr = value
            elif key == "worker_machine_image": self._worker_machine_image = value
            elif key == "expose_ui": self._expose_ui =value
            elif key == "peer_with": pass # ignore this key, will be traversed later
            else:
                logging.warn(f"Key {key} is being ignored ")

        if self._resource_name is None:
            self._resource_name = f'{deployment_name()}-{self._name}-vpc'
        
        cidr_list = list(self._private_cidr.keys())
        lb_list = list(self._lb_cidr.keys())
        cidr_list.sort()
        lb_list.sort()
        if cidr_list != lb_list:
            raise Exception("You must specify the lb_cidr for AWS networks to have the same number of elements than private_cidr")

        Provider("aws", region=self._region, access_key=os.getenv("AWS_ACCESS_KEY_ID", ""),
             secret_key=os.getenv("AWS_SECRET_ACCESS_KEY", ""), alias=self._name)
