#!/usr/bin/env python
# -*- coding: UTF-8 -*-
from abc import ABCMeta, abstractmethod
import sys
import logging
from typing import List

class Cloud_Provider_VPC_VNET(object):
    __metaclass__ = ABCMeta
    @abstractmethod
    def create_network(self) -> int:
        pass

    @abstractmethod
    def create_bastion(self) -> int:
        pass

    def set_ui(self,set_ui):
        self._expose_ui = set_ui

    def expose_re_ui(self) -> int:
        if self._expose_ui:
            return self.create_re_ui()
        return 0
        
    @abstractmethod
    def create_re_ui(self) -> int:
        pass

    def get_provider(self) -> str:
        return(self._provider)

    def get_region(self) -> str:
        return(self._region)

    def get_resource_group(self) -> str:
        return(self._resource_group)

    def get_peer_request_list(self):
        return(self._peer_request_list)

    def get_vpc_cidr(self) -> str:
        return(self._vpc_cidr)
    
    def get_private_cidr(self):
        return(self._private_cidr)

    def get_public_cidr(self):
        return(self._public_cidr)

    def add_peers(self,peer_list) -> int:
        from generator.generator import vpc
        for peer in peer_list:
            if peer not in vpc:
                raise Exception(f"ERROR: Requested peering vpc {peer} not found in config file")
            if peer not in self._peer_request_list and self._name not in vpc[peer].get_peer_request_list():
                # Same provider, go for VPC/VNET peering
                if self._provider == vpc[peer]._provider:
                    self._peer_request_list.append(peer)
                    vpc[peer].add_to_peer_accept_list(self._name)
                # Different provider, go for VPN
                else:
                    self._vpn_set.add(peer)
                    vpc[peer].add_to_vpn_set(self._name)
        return(0)

    def add_to_peer_accept_list(self,peer) -> int:
        self._peer_accept_list.append(peer)
        return(0)

    def add_to_vpn_set(self,peer) -> int:
        self._vpn_set.add(peer)
        return(0)

    def set_vpns(self,name,cidr,secret_key, external_ip) -> int:
        self._vpns.append({
        'name' : name,
        'cidr' : cidr,
        'secret_key' : secret_key,
        'external_ip' : external_ip})
        return(0)

    def get_vpns(self):
        return([s['name'] for s in self._vpns])

    def get_vpn_peers(self) -> set:
        return(self._vpn_set)

    def get_private_cidr(self) -> set:
        return(self._private_cidr)

    def create_vpn_secrets(self) -> str:
        import string
        import secrets
        from generator.generator import deployment_name
        if deployment_name() == "unit-test-name":
            return('unittestdummysecretkey')
        alphabet = string.ascii_letters + string.digits
        password = ''.join(secrets.choice(alphabet) for i in range(32))
        return(password)

    @classmethod
    def __init__(self, **kwargs):
        from generator.generator import global_config
        self._global_config = {}
        if "resource_tags" in global_config:
            self._global_config["resource_tags"] = global_config["resource_tags"]
        else:
            self._global_config["resource_tags"] = {}

        self._name : str = None
        self._region : str = None
        self._vpc_cidr = None,
        self._public_cidr : str = None
        self._private_cidr = None
        self._bastion_zone = None
        self._bastion_machine_image : str = None
        self._bastion_machine_type : str = None
        self._redis_cluster_name : str = "dtest.rlabs.org"
        self._expose_ui : bool = False
        self._provider = None
        self._resource_group = None
        self._connects = []
        self._peer_accept_list = []
        self._peer_request_list = []
        self._vpc_accept_list = []
        self._vpc_request_list = []
        self._vpn_set = set()
        self._vpns = []

        if not "provider" in kwargs:
            raise Exception("A provider must be specified for each network")

        if "name" not in kwargs:
            raise Exception("The VPC/VNET must have an attribute called name")
        if kwargs["name"] == "" or kwargs["name"] is None:
            raise Exception("The VPC or VNET must have a non-empty attribute called name")

