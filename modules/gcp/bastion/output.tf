output "bastion-public-ip" {
  value = google_compute_address.bastion-ip-address.address
}
