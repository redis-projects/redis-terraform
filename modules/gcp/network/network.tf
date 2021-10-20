terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

################################   ##subnet and route ##########################

resource "google_compute_subnetwork" "public-subnet" {
  name          = "${var.name}-public-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_public_subnet_cidr
  region = var.region
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "${var.name}-private-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_private_subnet_cidr
  region = var.region
}

resource "google_compute_router" "router" {
  name    = "${var.name}-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.vpc.self_link
  bgp {
    asn = 64514
  }
}


################################ nat  ############################

resource "google_compute_router_nat" "simple-nat" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


################################ fire wall ############################


resource "google_compute_firewall" "private-firewall" {
  name    = "${var.name}-private-firewall"
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

  source_ranges = concat([var.gce_public_subnet_cidr], [var.gce_private_subnet_cidr], var.cidr_list)
}

resource "google_compute_firewall" "private-ui-firewall" {
  name    = "${var.name}-private-ui-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
     ports    = ["8443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "public-firewall" {
  name    = "${var.name}-public-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "9443", "12000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "dns-firewall" {
  name    = "${var.name}-dns-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports = ["53"]
  }

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  source_ranges = ["0.0.0.0/0"]
}
