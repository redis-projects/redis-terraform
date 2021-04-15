resource "google_compute_network" "vpc" {
  name                    = var.vpc
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

################################   ##subnet and route ##########################

resource "google_compute_subnetwork" "public-subnet" {
  name          = "${var.vpc}-${var.random_id}-public-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_public_subnet_cidr
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "${var.vpc}-${var.random_id}-private-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_private_subnet_cidr
}

resource "google_compute_router" "router" {
  name    = "${var.vpc}-${var.random_id}-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.vpc.self_link
  bgp {
    asn = 64514
  }
}


################################ nat  ############################

resource "google_compute_router_nat" "simple-nat" {
  name                               = "${var.vpc}-${var.random_id}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


################################ fire wall ############################


resource "google_compute_firewall" "private-firewall" {
  name    = "${var.vpc}-${var.random_id}-private-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "tcp"
     ports    = ["0-65535"]
  }

  allow {
    protocol = "ipip"
  }

  source_ranges = [var.gce_public_subnet_cidr, var.gce_private_subnet_cidr, "130.211.0.0/22",  "35.191.0.0/16"]
}

resource "google_compute_firewall" "public-firewall" {
  name    = "${var.vpc}-${var.random_id}-public-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22","80", "443", "9443"]
  }

  source_ranges = ["0.0.0.0/0"]
}