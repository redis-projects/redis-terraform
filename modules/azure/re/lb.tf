# First, we create a public IP for the Load Balancer
resource "azurerm_public_ip" "re-dns-ip" {
  name                = "${var.name}-re-dns-lb-ip-address"
  location            = var.region
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.name}-dns-lb"
}

resource "azurerm_lb" "re-dns-lb" {
  name                = "${var.name}-re-dns-lb"
  location            = var.region
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.name}-re-dns-lb-fe-ip"
    public_ip_address_id = azurerm_public_ip.re-dns-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "re-dns-pool" {
  loadbalancer_id = azurerm_lb.re-dns-lb.id
  name            = "${var.name}-re-dns-pool"
}

resource "azurerm_lb_backend_address_pool_address" "re-dns-pool-ips" {
  name                    = "${var.name}-re-dns-pool-ips-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.re-dns-pool.id
  virtual_network_id      = var.vpc
  ip_address              = azurerm_network_interface.redis-nic[count.index].private_ip_address
  count                   = var.machine_count
}

resource "azurerm_lb_probe" "re-dns-lb-probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.re-dns-lb.id
  name                = "probe-port-8443"
  port                = 8443
}

resource "azurerm_lb_rule" "re-dns-lb-rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.re-dns-lb.id
  name                           = "${var.name}-re-dns-lb-rule"
  protocol                       = "udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "${var.name}-re-dns-lb-fe-ip"
  load_distribution              = "SourceIP"
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.re-dns-pool.id ]
  probe_id                       = azurerm_lb_probe.re-dns-lb-probe.id
}
