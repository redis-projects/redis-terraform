
import pytest
from exceptions_test_input import *
import os
from unittest.mock import Mock
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

@pytest.fixture(autouse=True)
def setMocks(monkeypatch, getenv):
    [monkeypatch.setenv(x, getenv[x]) for x in getenv]

    import providers

    providers.gcp = Mock()
    providers.aws = Mock()
    providers.azure = Mock()

    yield


@pytest.mark.parametrize("config_file", ["aws", "azure", "gcp", "mixed"] )
def test_register(monkeypatch, getenv, readconfigs, readexpected, config_file):
    [monkeypatch.setenv(x, getenv[x]) for x in getenv]
    import providers
    from generator import generator
    generator.generate(readconfigs[config_file])

    (exp_aws, exp_azure, exp_gcp) = readexpected[config_file]

    assert(exp_aws == json.loads(json.dumps(providers.aws.mock_calls)))
    assert(exp_azure == json.loads(json.dumps(providers.azure.mock_calls)))
    assert(exp_gcp == json.loads(json.dumps(providers.gcp.mock_calls)))

#Just a safe guard to ensure we are not testing with a mock since test_provider
#uses Mock and we don't want a leak
def test_providers_are_mock(monkeypatch, getenv):
    [monkeypatch.setenv(x, getenv[x]) for x in getenv]
    import providers
    from unittest.mock import Mock
    assert isinstance(providers.aws, Mock)
    assert isinstance(providers.azure, Mock)
    assert isinstance(providers.gcp, Mock)
