terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

resource "google_dns_record_set" "A-records" {
  provider = google-beta
  managed_zone = var.parent_zone
  name         = "node${count.index+1}.${var.cluster_fqdn}."
  type         = "A"
  rrdatas      = [ tostring(var.ip_addresses[count.index]) ]
  ttl          = 60
  count        = length(var.ip_addresses)
}

resource "google_dns_record_set" "NS-record" {
  provider     = google-beta
  managed_zone = var.parent_zone
  name         = "${var.cluster_fqdn}."
  type         = "NS"
  rrdatas      = tolist(google_dns_record_set.A-records.*.name)
  ttl          = 60
}