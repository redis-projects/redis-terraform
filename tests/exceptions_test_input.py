network_no_provider = ({"networks": [{}]}, "ERROR: a provider must be specified for each network (google or aws)")
nameservers_no_domain = ({"nameservers": [{}]}, "Please supply domain for all nameservers")
network_invalid_peer_with = ({"networks": [{
    "provider": "aws",
    "name": "vpc-1",
    "peer_with": [
        "vpc-2"
    ]
}]}, "ERROR: Requested peering vpc vpc-2 not found in config file")
network_different_providers = ({"networks": [{
    "provider": "aws",
    "name": "vpc-1",
    "peer_with": [
        "vpc-2"
    ]
}, {
    "provider": "gcp",
    "name": "vpc-2"
}]}, "ERROR: Peering network vpc-2 uses different provider (gcp) than requester vpc (aws)")
network_unsupported_provider = ({"networks": [{
    "provider": "utprov",
    "name": "vpc-1",
    "region": "region-1"}]}, "unsupported provider utprov")
nameserver_no_domain = ({
    "nameservers": [
        {
            "vpc": "vpc-1"
        }
    ]
    }, "Please supply domain for all nameservers")

nameserver_unsupported_provider = ({"networks": [{
    "provider": "utprov",
    "name": "vpc-1",
    "region": "region-1"}],
    "nameservers": [
        {
            "domain": "unittest.domain.com",
            "vpc": "vpc-1"
        }
    ]
    }, "unsupported provider utprov")