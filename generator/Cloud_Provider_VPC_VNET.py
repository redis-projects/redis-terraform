#!/usr/bin/env python
# -*- coding: UTF-8 -*-
from abc import ABCMeta, abstractmethod
import sys
import generator.generator
import generator.Cluster
import generator.Host
import generator.Nameserver_Entries
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
        for peer in peer_list:
            if peer not in self._peer_request_list and self._name not in generator.generator.vpc[peer].get_peer_request_list():
                # Same provider, go for VPC/VNET peering
                if self._provider == generator.generator.vpc[peer]._provider:
                    self._peer_request_list.append(peer)
                    generator.generator.vpc[peer].add_to_peer_accept_list(self._name)
        return(0)

    def add_to_peer_accept_list(self,peer) -> int:
        self._peer_accept_list.append(peer)
        return(0)

    @classmethod
    def __init__(self, **kwargs):
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
        self._vpn_accept_list = []
        self._vpn_request_list = []
        """# @AssociationMultiplicity *"""
        self._contains : generator.Cluster.Cluster = None
        """# @AssociationMultiplicity 1
        # @AssociationKind Composition"""
        self._contains_bastion : generator.Host.Host = None
        """# @AssociationMultiplicity 1
        # @AssociationKind Composition"""
        self._unnamed_Nameserver_Entries_ : generator.Nameserver_Entries.Nameserver_Entries = None
        """# @AssociationKind Composition"""
        if "name" not in kwargs:
            logging.error("The VPC/VNET must have an attribute called name")
            sys.exit(1)
        if kwargs["name"] == "" or kwargs["name"] is None:
            logging.error("The VPC or VNET must have a non-empty attribute called name")
