resource "google_compute_target_pool" "dns" {
  name = "${var.name}-dns-lb"
  session_affinity = "NONE"
  instances = [
    for node in google_compute_instance.node :
     format("%s/%s",node.zone, node.name)
  ]

  health_checks = [ google_compute_http_health_check.dns.name ]
}

# health check
resource "google_compute_http_health_check" "dns" {
  name               = "${var.name}-dns-health"
  request_path       = "/"
  check_interval_sec = 15
  port               = 8443
}

resource "google_compute_address" "dns" {
  name         = "${var.name}-dns-lb"
  address_type = "EXTERNAL"
}

# backend to forward port 53 (dns)
resource "google_compute_forwarding_rule" "dns" {
  name        = "${var.name}-dns-fe"
  port_range  = "53"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.dns.address 
  target      = google_compute_target_pool.dns.id
}
