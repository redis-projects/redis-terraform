#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import sys
import logging
from terraformpy import Module, Provider, Data, Output
from typing import List

class Nameserver_Entries(object):
    def create_ns_records(self):
        
        from generator.generator import deployment_name, vpc, re_cluster

        if self._provider== "azure":
            Module(f"ns-{self._vpc}",
                source         = f"./modules/{self._provider}/ns",
                providers      = {"azurerm": f"azurerm.{self._vpc}"},
                cluster_fqdn   = self._cluster_fqdn,
                parent_zone    = self._parent_zone,
                ip_addresses   = f'${{module.re-{self._vpc}.re-public-ips}}',
                resource_tags  = self._global_config["resource_tags"],
                resource_group = vpc[self._vpc].get_resource_group()
            )
        elif self._provider== "aws":
            Module(f"ns-{self._vpc}",
                source        = f"./modules/{self._provider}/ns",
                providers     = {"aws": f"aws.{self._vpc}"},
                cluster_fqdn  = self._cluster_fqdn,
                parent_zone   = self._parent_zone,
                resource_tags = self._global_config["resource_tags"],
                ip_addresses  = f'${{module.re-{self._vpc}.re-public-ips}}'
            )
        elif self._provider== "gcp":
            Module(f"ns-{self._vpc}",
                source        = f"./modules/{self._provider}/ns",
                providers     = {"google-beta": f"google-beta.{self._vpc}"},
                cluster_fqdn  = self._cluster_fqdn,
                parent_zone   = self._parent_zone,
                resource_tags = self._global_config["resource_tags"],
                ip_addresses  = f'${{module.re-{self._vpc}.re-public-ips}}'
            )

        Output(f"{self._vpc}-dns-name", value = self._cluster_fqdn)
        if self._cluster not in re_cluster:
            logging.error(f"The specified cluster ({self._cluster}) is not found in the 'clusters' section")
            sys.exit(1)
        re_cluster[f"{self._cluster}"].set_cluster_name(self._cluster_fqdn)

    def get_domain(self):
        return(self._domain)

    def get_cluster(self):
        return(self._cluster)

    def __init__(self, **kwargs):
        from generator.generator import deployment_name, vpc, global_config
        self._global_config = {}
        if "resource_tags" in global_config:
            self._global_config["resource_tags"] = global_config["resource_tags"]
        else:
            self._global_config["resource_tags"] = {}
        self._domain : str = None
        self._parent_zone : str = None
        self._vpc : str = None
        self._cluster : str = None
        self._provider : str = None
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))
        for key, value in kwargs.items():
            if key == "provider": self._provider = value
            elif key == "domain": self._domain = value
            elif key == "parent_zone": self._parent_zone = value
            elif key == "vpc": self._vpc = value
            elif key == "cluster": self._cluster = value
            elif key == "provider": self._provider = value
            else:
                logging.warn(f"Class {self.__class__.__name__}: Key {key} is being ignored ")
        
        # If provider was not set, assume provider is identical to the VPC/VNET provider
        if self._provider == None:
            self._provider = vpc[self._vpc].get_provider()

        if not self._cluster:
            logging.error(f"Property 'cluster' required for each entry of 'nameservers'")
            sys.exit(1)
        if not self._vpc:
            logging.error(f"Property 'vpc' required for each entry of 'nameservers'")
            sys.exit(1)
        if not self._domain:
            logging.error(f"Property 'domain' required for each entry of 'nameservers'")
            sys.exit(1)
        if not self._parent_zone:
            logging.error(f"Property 'parent_zone' required for each entry of 'nameservers'")
            sys.exit(1)

        self._cluster_fqdn = f"{deployment_name()}-{self._cluster}.{self._domain}"
        

