resource "google_compute_network_peering" "peer-request" {
  name         = "${var.name}-peer-request-${count.index}"
  network      = google_compute_network.vpc.id
  peer_network = var.vpc_request_list[count.index]
  count         = length(var.vpc_request_list)
}

resource "google_compute_network_peering" "peer-accept" {
  name         = "${var.name}-peer-accept-${count.index}"
  network      = google_compute_network.vpc.id
  peer_network = var.vpc_accept_list[count.index]
  count         = length(var.vpc_accept_list)
}

