valid_network = {"networks": [{
    "provider": "gcp",
    "name": "vpc-1"
}]}

network_no_provider = ({"networks": [{}]}, "A provider must be specified for each network")

n1 = {"nameservers": [{}]}
n1.update(valid_network)
nameservers_no_vpc = (n1, "Property 'vpc' required for each entry of 'nameservers'")

n2 = {"nameservers": [{"vpc": "vpc-1"}]}
n2.update(valid_network)
nameservers_no_cluster = (n2, "Property 'cluster' required for each entry of 'nameservers'")

n3 = {"nameservers": [{"vpc": "vpc-1", "cluster": "cluster"}]}
n3.update(valid_network)
nameservers_no_domain = (n3, "Property 'domain' required for each entry of 'nameservers'")

n4 = {"nameservers": [{"vpc": "vpc-1", "cluster": "cluster", "domain": "blah.blah.com", "parent_zone": "parent_zone"}]}
n4.update(valid_network)
nameservers_invalid_cluster = (n4, "The specified cluster (cluster) is not found in the 'clusters' section")

network_invalid_peer_with = ({"networks": [{
    "provider": "gcp",
    "name": "vpc-1",
    "peer_with": [
        "vpc-2"
    ]
}]}, "ERROR: Requested peering vpc vpc-2 not found in config file")

#NO LONGER VALID AS WE NOW HAVE VPN PEERING
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
    "region": "region-1"}]}, "network vpc-1 has an unsupported provider utprov")

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
    }, "network vpc-1 has an unsupported provider utprov")