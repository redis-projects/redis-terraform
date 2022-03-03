output "ui-ip" {
  value = length(var.ui_subnet) == 0 ? google_compute_address.re-ui-ip-external[0] : google_compute_address.re-ui-ip-internal[0]
}
