#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
import generator.generator
import generator.Cloud_Provider_VPC_VNET
from terraformpy import Module, Provider, Data, Output
from typing import List

class Nameserver_Entries(object):
    def create_ns_records(self):
        
        if self._provider== "azure":
            Module(f"ns-{self._vpc}",
                source         = f"./modules/{self._provider}/ns",
                providers      = {"azurerm": f"azurerm.{self._vpc}"},
                cluster_fqdn   = self._cluster_fqdn,
                parent_zone    = self._parent_zone,
                ip_addresses   = f'${{module.re-{self._vpc}.re-public-ips}}',
                resource_group = generator.generator.vpc[self._vpc].get_resource_group()
            )
        elif self._provider== "aws":
            Module(f"ns-{self._vpc}",
                source       = f"./modules/{self._provider}/ns",
                name         = f'{generator.generator.deployment_name()}-{self._vpc}',
                providers    = {"aws": f"aws.{self._vpc}"},
                cluster_fqdn = self._cluster_fqdn,
                parent_zone  = self._parent_zone,
                ip_addresses = f'${{module.re-{self._vpc}.re-public-ips}}'
            )
        elif self._provider== "gcp":
            Module(f"ns-{self._vpc}",
                source       = f"./modules/{self._provider}/ns",
                name         = f'{generator.generator.deployment_name()}-{self._vpc}',
                providers    = {"google-beta": f"google-beta.{self._vpc}"},
                cluster_fqdn = self._cluster_fqdn,
                parent_zone  = self._parent_zone,
                ip_addresses = f'${{module.re-{self._vpc}.re-public-ips}}'
            )

        Output(f"{self._vpc}-dns-name", value = self._cluster_fqdn)

        generator.generator.re_cluster[self._vpc].set_cluster_name(self._cluster_fqdn)

    def get_domain(self):
        return(self._domain)

    def __init__(self, **kwargs):
        self._domain : str = None
        self._parent_zone : str = None
        self._vpc : str = None
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))
        for key, value in kwargs.items():
            if key == "provider": self._provider = value
            elif key == "domain": self._domain = value
            elif key == "parent_zone": self._parent_zone = value
            elif key == "vpc": self._vpc = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")
        self._cluster_fqdn = f"{generator.generator.deployment_name()}-{self._vpc}.{self._domain}"
        self._provider = generator.generator.vpc[self._vpc].get_provider()

