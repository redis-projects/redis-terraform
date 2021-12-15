#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import generator.Cluster
import generator.Cloud_Provider_VPC_VNET
import generator.Service
from typing import List

class Host(object):
    def Host(self):
        pass

    def setPublic_ip(self, aPublic_ip : str):
        self._public_ip = aPublic_ip

    def getPublic_ip(self) -> str:
        return self._public_ip

    def setPrivate_ip(self, aPrivate_ip : str):
        self._private_ip = aPrivate_ip

    def getPrivate_ip(self) -> str:
        return self._private_ip

    def __init__(self):
        self._machine_type : str = None
        self._machine_image : str = None
        self._availability_zone : str = None
        self._public_ip : str = None
        self._private_ip : str = None
        self._contains : generator.Cluster.Cluster = None
        """# @AssociationMultiplicity 1"""
        self._contains_bastion : generator.Cloud_Provider_VPC_VNET.Cloud_Provider_VPC_VNET = None
        """# @AssociationMultiplicity 1"""
        self._runs_on : generator.Service.Service = None
        """# @AssociationMultiplicity 1"""

