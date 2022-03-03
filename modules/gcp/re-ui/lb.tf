terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

# compute pool that points at the proxy

resource "google_compute_target_pool" "default" {
  name = "${var.name}-lb"
  session_affinity = "CLIENT_IP"
  instances = [
    for i, name in var.instances :
     format("%s/%s",var.zones[i],name)
  ]

  health_checks = [ google_compute_http_health_check.default.name ]
}

# health check
resource "google_compute_http_health_check" "default" {
  name               = "${var.name}-healthcheck"
  request_path       = "/"
  check_interval_sec = 15
  port               = 8443
}

resource "google_compute_address" "re-ui-ip-external" {
  count        = length(var.ui_subnet) == 0 ? 1 : 0
  name         = "${var.name}-re-ui-lb-ip-address"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "re-ui-ip-internal" {
  count        = length(var.ui_subnet) == 0 ? 0 : 1
  name         = "${var.name}-re-ui-lb-ip-address"
  subnetwork   = var.ui_subnet[0].id
  address_type = "INTERNAL"
}

# backend to forward port 443
resource "google_compute_forwarding_rule" "tls" {
  name       = "${var.name}-tls"
  port_range = "8443"
  ip_address = length(var.ui_subnet) == 0 ? google_compute_address.re-ui-ip-external[0].address : google_compute_address.re-ui-ip-internal[0].address 
  target     = google_compute_target_pool.default.id
}

resource "google_dns_record_set" "a" {
  name         = "${var.name}.ps-redislabs.com."
  type         = "A"
  ttl          = 60
  managed_zone = "ps-redislabs"
  rrdatas      = length(var.ui_subnet) == 0 ? [ google_compute_address.re-ui-ip-external[0].address ] : [ google_compute_address.re-ui-ip-internal[0].address ]
}
