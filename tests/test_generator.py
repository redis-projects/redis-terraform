
import pytest
from exceptions_test_input import *

@pytest.fixture(autouse=True)
def getenv():
    envs = {
        "name": "unit-test-name"
    }
    yield envs

@pytest.mark.parametrize("test_input,expected_exception", [
        network_no_provider,
        nameservers_no_domain,
        network_invalid_peer_with,
        network_different_providers,
        network_unsupported_provider,
        nameserver_no_domain,
        nameserver_unsupported_provider
    ] )
def test_exceptions(monkeypatch, getenv, test_input, expected_exception):
    [monkeypatch.setenv(x, getenv[x]) for x in getenv]
    from generator import generator
    with pytest.raises(Exception) as excinfo:
        generator.generate(test_input)
    assert expected_exception == str(excinfo.value)

def test_peering():
    pass
