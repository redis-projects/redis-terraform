locals {
  aws_vpn = flatten([
    for vpn in var.aws_vpns : [
      for cidr in vpn.cidr_list : {
        name = vpn.name
        cidr = cidr
        #tunnel_hop = "${google_compute_vpn_tunnel.azure_vpn_tunnel[count.index].self_link}"
      }
    ]
  ])
}

resource "google_compute_address" "gcp_vpn_ip" {
  name   = "${var.name}-vpn-ip"
  region = "${var.region}"
  count  = min(length(var.vpn_list),1)
}

resource "google_compute_vpn_gateway" "gcp_vpn_gateway" {
  name    = "${var.name}-vpn-gateway"
  network = "${google_compute_network.vpc.name}"
  region  = "${var.region}"
  count   = min(length(var.vpn_list),1)
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "${var.name}-fr-esp"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.gcp_vpn_ip[0].address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  count       = min(length(var.vpn_list),1)
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "${var.name}-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = "${google_compute_address.gcp_vpn_ip[0].address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  count       = min(length(var.vpn_list),1)
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "${var.name}-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = "${google_compute_address.gcp_vpn_ip[0].address}"
  target      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  count       = min(length(var.vpn_list),1)
}

resource "google_compute_vpn_tunnel" "azure_vpn_tunnel" {
  name                    = "${var.name}-vpn-tunnel-${var.gcp_azure_vpns[count.index].name}"
  peer_ip                 = "${var.gcp_azure_vpns[count.index].external_ip}"
  ike_version             = 2
  shared_secret           = "${var.gcp_azure_vpns[count.index].secret_key}" 
  target_vpn_gateway      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  local_traffic_selector  = ["${var.gce_public_subnet_cidr}", "${var.gce_private_subnet_cidr}"]
  remote_traffic_selector = ["${var.gcp_azure_vpns[count.index].cidr}"]
  count                   = length(var.gcp_azure_vpns)

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "aws_vpn_tunnelA" {
  name                    = "${var.name}-vpn-tunnel-a-${var.aws_vpns[count.index].name}"
  peer_ip                 = "${var.aws_vpns[count.index].external_ip[var.vpc_name].tunnel1_address}"
  ike_version             = 2
  shared_secret           = "${var.aws_vpns[count.index].secret_key}" 
  target_vpn_gateway      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  local_traffic_selector  = ["${var.gce_public_subnet_cidr}", "${var.gce_private_subnet_cidr}"]
  remote_traffic_selector = "${var.aws_vpns[count.index].cidr_list}"
  count                   = length(var.aws_vpns)

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "aws_vpn_tunnelB" {
  name                    = "${var.name}-vpn-tunnel-b-${var.aws_vpns[count.index].name}"
  peer_ip                 = "${var.aws_vpns[count.index].external_ip[var.vpc_name].tunnel2_address}"
  ike_version             = 2
  shared_secret           = "${var.aws_vpns[count.index].secret_key}" 
  target_vpn_gateway      = "${google_compute_vpn_gateway.gcp_vpn_gateway[0].self_link}"
  local_traffic_selector  = ["${var.gce_public_subnet_cidr}", "${var.gce_private_subnet_cidr}"]
  remote_traffic_selector = "${var.aws_vpns[count.index].cidr_list}"
  count                   = length(var.aws_vpns)

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_route" "azure_route" {
  name                = "${var.name}-vpnroute-${var.gcp_azure_vpns[count.index].name}"
  dest_range          = "${var.gcp_azure_vpns[count.index].cidr}"
  network             = "${google_compute_network.vpc.self_link}"
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.azure_vpn_tunnel[count.index].self_link}"
  priority            = 100
  count               = length(var.gcp_azure_vpns)
  depends_on = [
    google_compute_vpn_tunnel.azure_vpn_tunnel
  ]
}

resource "google_compute_route" "awsrouteA" {
  #name                = "${var.name}-vpnrouteA-${local.aws_vpn[count.index].name}-${count.index}"
  name                = "${var.name}-vpnroute-a-${local.aws_vpn[count.index].name}-${count.index}"
  dest_range          = "${local.aws_vpn[count.index].cidr}"
  network             = "${google_compute_network.vpc.self_link}"
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.aws_vpn_tunnelA[0].self_link}"
  priority            = 100
  count               = length(local.aws_vpn)
  depends_on = [
    google_compute_vpn_tunnel.aws_vpn_tunnelA
  ]
}

resource "google_compute_route" "awsrouteB" {
  name                = "${var.name}-vpnroute-b-${local.aws_vpn[count.index].name}-${count.index}"
  dest_range          = "${local.aws_vpn[count.index].cidr}"
  network             = "${google_compute_network.vpc.self_link}"
  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.aws_vpn_tunnelB[0].self_link}"
  priority            = 100
  count               = length(local.aws_vpn)
  depends_on = [
    google_compute_vpn_tunnel.aws_vpn_tunnelB
  ]
}
