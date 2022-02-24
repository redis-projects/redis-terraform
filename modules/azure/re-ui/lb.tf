# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# First, we create a public IP for the Load Balancer
resource "azurerm_public_ip" "re-ui-ip" {
  name                = "${var.name}-re-ui-lb-ip-address"
  location            = var.region
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "re-ui-lb" {
  name                = "${var.name}-re-ui-lb"
  location            = var.region
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.name}-re-ui-lb-fe-ip"
    public_ip_address_id = azurerm_public_ip.re-ui-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "re-ui-pool" {
  loadbalancer_id = azurerm_lb.re-ui-lb.id
  name            = "${var.name}-re-ui-pool"
}

resource "azurerm_lb_backend_address_pool_address" "re-ui-pool-ips" {
  name                    = "${var.name}-re-ui-pool-ips-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.re-ui-pool.id
  virtual_network_id      = var.vnet
  ip_address              = var.instances[count.index]
  count                   = length(var.instances)
}

resource "azurerm_lb_probe" "re-ui-lb-probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.re-ui-lb.id
  name                = "probe-port-8443"
  port                = 8443
}

resource "azurerm_lb_rule" "re-ui-lb-rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.re-ui-lb.id
  name                           = "${var.name}-re-ui-lb-rule"
  protocol                       = "tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  frontend_ip_configuration_name = "${var.name}-re-ui-lb-fe-ip"
  load_distribution              = "SourceIP"
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.re-ui-pool.id ]
  probe_id                       = azurerm_lb_probe.re-ui-lb-probe.id
}