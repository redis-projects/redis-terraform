#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import logging
from typing import List

class Databases(object):
    def provision_db(self):
        pass

    def Databases(self):
        pass

    def __init__(self, **kwargs):
        self._name : str = None
        self._shards : int = None
        self._size_in_mb : int = None
        self._cluster_fqdns = None
        self._causal_consistency : bool = True
        self._replication : bool = True
        self._encryption : bool = True
        self._oss_sharding : bool = True
        self._oss_cluster : bool = True
        self._port : int = 12000
        self._runs_on = []
        """# @AssociationMultiplicity 1..*"""
        logging.debug("Creating Object of class "+self.__class__.__name__+" with class arguments "+str(kwargs))

