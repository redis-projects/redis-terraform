import collections
import json

import pytest
#import schematics.types
import six

from terraformpy import (
    Data,
    Module,
    OrderedDict,
    Provider,
    Resource,
    Terraform,
    TFObject,
    Variable,
    Variant,
)


def test_object_instances():
    res = Resource("res1", "foo", attr="value")
    var = Variable("var1", default="foo")

    print(Resource._instances)
    assert TFObject._instances is None
    assert Resource._instances != [res]
    assert Variable._instances == [var]