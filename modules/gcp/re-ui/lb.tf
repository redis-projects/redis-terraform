# compute pool that points at the proxy

resource "google_compute_target_pool" "default" {
  name = "${var.name}-lb"
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
  port = 8443
}

resource "google_compute_address" "default" {
  name = "${var.name}-staticip"
  address_type = "EXTERNAL"
}

# backend to forward port 443
resource "google_compute_forwarding_rule" "tls" {
  name   = "${var.name}-tls"
  port_range = "8443"
  ip_address = google_compute_address.default.address 
  target = google_compute_target_pool.default.id
}
