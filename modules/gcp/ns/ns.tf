terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

resource "google_dns_record_set" "A-record" {
  provider = google-beta
  managed_zone = var.parent_zone
  name         = "dns-lb-${var.cluster_fqdn}."
  type         = "A"
  rrdatas      = [ var.dns_lb_name ]
  ttl          = 60
}

resource "google_dns_record_set" "NS-record" {
  provider     = google-beta
  managed_zone = var.parent_zone
  name         = "${var.cluster_fqdn}."
  type         = "NS"
  rrdatas      = [ google_dns_record_set.A-record.name ]
  ttl          = 60
}
