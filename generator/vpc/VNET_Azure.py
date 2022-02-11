#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from generator import SSH_USER, SSH_PUBLIC_KEY
from generator.vpc.Cloud_Provider_VPC_VNET import Cloud_Provider_VPC_VNET

from terraformpy import Module, Provider, Data, Output
from typing import List

class VNET_Azure(Cloud_Provider_VPC_VNET):
    def create_network(self) -> int:

        vpn_list = list(self._vpn_set)
        vpc_request_list = [f'${{module.network-{s}.vpc}}' for s in self._peer_request_list]
        vpc_accept_list  = [f'${{module.network-{s}.vpc}}' for s in self._peer_accept_list]
        vpn_connections  = [f'${{module.network-{s}.vpn_connection}}' for s in vpn_list]
        vpn_vpc_list     = [f'${{module.network-{s}.raw_vpc}}' for s in vpn_list]

        Module("network-%s" % self._name, source="./modules/azure/network",
             name                = '%s-%s' % (os.getenv("name"), self._name),
             resource_name       = self._resource_name,
             resource_tags       = self._global_config["resource_tags"],
             vpc_cidr            = self._vpc_cidr,
             public_subnet_cidr  = self._public_cidr,
             private_subnet_cidr = self._private_cidr,
             gateway_subnet_cidr = self._gateway_cidr,
             region              = self._region,
             resource_group      = self._resource_group,
             expose_ui           = self._expose_ui,
             vpc_request_list    = vpc_request_list,
             vpc_accept_list     = vpc_accept_list,
             vpn_list            = vpn_list,
             vpn_connections     = vpn_connections,
             vpn_vpc_list        = vpn_vpc_list,
             providers           = {"azurerm": "azurerm.%s" % self._name})


    def create_bastion(self) -> int:
        from generator.generator import deployment_name
        Module(f"bastion-{self._name}",
            source                   = f"./modules/{self._provider}/bastion",
            name                     = f'{deployment_name()}-{self._name}',
            region                   = self._region,
            resource_group           = self._resource_group,
            public_subnet_id         = f'${{module.network-{self._name}.public-subnet}}',
            public_secgroup          = f'${{module.network-{self._name}.public-security-groups}}',
            os                       = self._bastion_machine_image,
            bastion_machine_type     = self._bastion_machine_type,
            bastion_machine_plan     = self._bastion_machine_plan,
            ssh_user                 = self._redis_user,
            ssh_pub_key_file         = self._ssh_public_key,
            providers                = {"azurerm": f"azurerm.{self._name}"}
        )

        Output(f"Azure-bastion-{self._name}-ip-output",
             value = f"${{module.bastion-{self._name}.bastion-public-ip}}")

    def create_re_ui(self) -> int:
        from generator.generator import deployment_name
        Module(f"re-ui-{self._name}",
            source            = f"./modules/{self._provider}/re-ui",
            name              = f'{deployment_name()}-{self._name}',
            instances         = f'${{module.re-{self._name}.re-nodes.*.private_ip_address}}',
            providers         = {"azurerm": f"azurerm.{self._name}"},
            vnet              = f'${{module.network-{self._name}.vpc}}',
            region            = self._region,
            resource_group    = self._resource_group
        )

        Output(f"re-ui-{self._name}-ip-output",
            value = f'${{module.re-ui-{self._name}.ui-ip}}')
        return(0)
    
    def getProvider(self) -> str:
        return self._provider

    def get_resource_group(self) -> str:
        return self._resource_group

    def __init__(self, **kwargs):
        from generator.generator import deployment_name
        super().__init__(**kwargs)
        self._application_id : str = os.getenv("AZURE_ACCESS_KEY_ID","")
        self._bastion_machine_type : str = "Standard_B1s"
        self._bastion_machine_image : str = "cognosys:centos-8-3-free:centos-8-3-free:1.2019.0810"
        self._bastion_machine_plan : str = ""
        self._bastion_zone = "2"
        self._client_certificate_path : str = None
        self._client_secret : str = os.getenv("AZURE_SECRET_ACCESS_KEY", "")
        self._name : str = None
        self._private_cidr = "10.2.2.0/24"
        self._provider : str = "azure"
        self._public_cidr : str = "10.2.1.0/24"
        self._gateway_cidr : str = "10.2.3.0/27"
        self._lb_cidr = {}
        self._region : str = "WestUS3"
        self._resource_group : str = None
        self._subscription_id : str = None
        self._tenant_id : str = None
        self._vpc_cidr : str = "10.2.0.0/16"
        self._worker_machine_image : str = "cognosys:centos-8-3-free:centos-8-3-free:1.2019.0810"
        self._resource_name : str = None
        self._redis_user = SSH_USER
        self._ssh_public_key = SSH_PUBLIC_KEY
        self._expose_ui : bool = True
        self._peer_accept_list = []
        self._peer_request_list = []
        self._vpc_accept_list = []
        self._vpc_request_list = []
        self._vpn_set = set()

        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

        for key, value in kwargs.items():
            if key == "application_id": self._application_id = value
            elif key == "bastion_machine_image": self._bastion_machine_image = value
            elif key == "bastion_machine_type": self._bastion_machine_type = value
            elif key == "bastion_machine_plan": self._bastion_machine_plan = value
            elif key == "bastion_zone": self._bastion_zone = value
            elif key == "client_certificate_path": self._client_certificate_path = value
            elif key == "client_secret": self._client_secret = value
            elif key == "name": self._name = value
            elif key == "private_cidr": self._private_cidr = value
            elif key == "public_cidr": self._public_cidr = value
            elif key == "lb_cidr": self._lb_cidr = value
            elif key == "gateway_cidr": self._gateway_cidr = value
            elif key == "provider": self._provider = value
            elif key == "region": self._region = value
            elif key == "resource_group": self._resource_group = value
            elif key == "subscription_id": self._subscription_id = value
            elif key == "tenant_id": self._tenant_id = value
            elif key == "vpc_cidr": self._vpc_cidr = value
            elif key == "worker_machine_image": self._worker_machine_image = value
            elif key == "expose_ui": self._expose_ui = value
            elif key == "resource_name": self._resource_name = value
            elif key == "peer_with": pass # ignore this key, will be traversed later
            else:
                logging.warn(f"Key {key} is being ignored ")
        
        if self._resource_name is None:
            self._resource_name = f'{deployment_name()}-{self._name}-vpc'

        if self._client_certificate_path is None and self._client_secret == "":
            assert("Either the client_certificate_path or the client_secret must bespecified for an Azure VNET (vpc)")
        elif self._client_certificate_path is not None and self._client_secret != "":
            assert("You must specify either the client_certificate_path or the client_secret (or $AZURE_SECRET_ACCESS_KEY) for an Azure VNET (vpc), not both!")
        elif self._client_certificate_path is not None:
            Provider("azurerm", features={}, client_id=self._application_id, tenant_id=self._tenant_id,
              subscription_id=self._subscription_id, client_certificate_path=self._client_certificate_path,
              alias=self._name)
        else:
            Provider("azurerm", features={}, client_id=self._application_id, tenant_id=self._tenant_id,
              subscription_id=self._subscription_id, client_secret=self._client_secret,
              alias=self._name)