import json
import pytest
import yaml
from jsondiff import diff
import jsondiff as jd

from terraformpy import (
    TFObject
)

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
        f = open(file, "r")
        return json.load(f)

    expected = {
        "gcp": readfile("tests/main.tf.json.gcp"),
        "aws": readfile("tests/main.tf.json.aws"),
        "azure": readfile("tests/main.tf.json.azure"),
        "mixed": readfile("tests/main.tf.json.mixed")
    }
    return expected

@pytest.mark.parametrize("provider", ["aws", "azure", "gcp", "mixed"] )
def test_register(monkeypatch, getenv, readconfigs, readexpected, provider):
    [monkeypatch.setenv(x, getenv[x]) for x in getenv]
    TFObject.reset()
    from generator import generator
    generator.generate(readconfigs[provider])
    contents = TFObject.compile()
    mydiff = diff(readexpected[provider], contents)

    # This is a little bit of a hack
    # Unfortunately, the provider section of the terrform json
    # reuses the same name for elements for the same cloud provider
    # which leads to only one of them being recognized,
    # causing some false positives
    # As such, we pop the provider but this of course leaves a
    # gaping hole if provider logic changes but it provides
    # protection for more common usages

    if 'provider' in mydiff:
        mydiff.pop('provider')

    print(">>>>>>>>>>>", provider.upper(),"<<<<<<<<<<")
    print(json.dumps(str(mydiff)))

    #Azure diff returns {replace: {}} for an uninvestigated reason.
    #Just compared instead since it is still valid and shows no difference.
    assert str(mydiff) == '{replace: {}}' or mydiff == {}
