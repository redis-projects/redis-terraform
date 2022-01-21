
import pytest
from exceptions_test_input import *
import os
from unittest.mock import Mock, patch
import yaml
import json

@pytest.fixture(autouse=True)
def getenv():
    envs = {
        "name": "unit-test-name"
    }
    yield envs

@pytest.fixture(autouse=True)
def readconfigs():
    def readfile(file):
        f = open(file, "r")
        return yaml.load(f, Loader=yaml.FullLoader)

    configs = {
        "gcp": readfile("config.yaml.gcp"),
        "aws": readfile("config.yaml.aws"),
        "azure": readfile("config.yaml.azure"),
        "mixed": readfile("config.yaml.mixed")
    }
    return configs

@pytest.fixture(autouse=True)
def readexpected():
    def readfile(file):
        f = open(file + ".aws", "r")
        fg = open(file + ".gcp", "r")
        fz = open(file + ".azure", "r")

        return (json.load(f), json.load(fz), json.load(fg))

    expected = {
        "gcp": readfile("tests/provider.test.gcp"),
        "aws": readfile("tests/provider.test.aws"),
        "azure": readfile("tests/provider.test.azure"),
        "mixed": readfile("tests/provider.test.mixed")
    }
    return expected

@pytest.mark.parametrize("config_file", ["aws", "azure", "gcp", "mixed"] )
@patch('generator.vpc.VPC_GCP.VPC_GCP')
@patch('generator.vpc.VNET_Azure.VNET_Azure')
@patch('generator.vpc.VPC_AWS.VPC_AWS')
def test_register(aws_mock, azure_mock, gcp_mock, getenv, readconfigs, readexpected, config_file):
    aws_mock.return_value.get_provider.return_value = "aws"
    azure_mock.return_value.get_provider.return_value = "azure"
    gcp_mock.return_value.get_provider.return_value = "gcp"

    from generator import generator, vpc
    generator.generate(readconfigs[config_file])

    (exp_aws, exp_azure, exp_gcp) = readexpected[config_file]

    assert(exp_aws == json.loads(json.dumps(aws_mock.mock_calls)))
    assert(exp_azure == json.loads(json.dumps(azure_mock.mock_calls)))
    assert(exp_gcp == json.loads(json.dumps(gcp_mock.mock_calls)))
