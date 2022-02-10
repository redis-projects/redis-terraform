#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import logging
from terraformpy import Module, Provider, Data, Output
from typing import List

class Servicenodes(object):
    def get_provider(self):
        return(self._provider)
    
    def get_vpc(self):
        return(self._vpc)
    
    def get_count(self):
        return(self._count)

    def __init__(self):
        from generator.generator import global_config
        self._global_config = {}
        if "resource_tags" in global_config:
            self._global_config["resource_tags"] = global_config["resource_tags"]
        else:
            self._global_config["resource_tags"] = {}
 


        

