# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Create an internal IP if the UI is exposed internally
resource "google_compute_address" "re-ui-ip" {
  count        = length(var.ui_subnet) == 0 ? 0 : 1
  name         = "${var.name}-re-ui-lb-ip-address"
  subnetwork   = var.ui_subnet[0].id
  address_type = "INTERNAL"
  region       = var.region
}
# Create a public IP for the Load Balancer if the UI is exposed externally
resource "azurerm_public_ip" "re-ui-ip" {
  count               = length(var.ui_subnet) == 0 ? 1 : 0
  name                = "${var.name}-re-ui-lb-ip-address"
  location            = var.region
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "re-ui-lb-external" {
  count               = length(var.ui_subnet) == 0 ? 1 : 0
  name                = "${var.name}-re-ui-lb"
  location            = var.region
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.name}-re-ui-lb-fe-ip"
    public_ip_address_id = azurerm_public_ip.re-ui-ip[0].id 
  }
}

resource "azurerm_lb" "re-ui-lb-internal" {
  count               = length(var.ui_subnet) == 0 ? 0 : 1
  name                = "${var.name}-re-ui-lb"
  location            = var.region
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "${var.name}-re-ui-lb-fe-ip"
    subnet_id = var.ui_subnet[0].id 
  }
}

resource "azurerm_lb_backend_address_pool" "re-ui-pool" {
  loadbalancer_id = length(var.ui_subnet) == 0 ? azurerm_lb.re-ui-lb-external[0].id : azurerm_lb.re-ui-lb-internal[0].id
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
  loadbalancer_id     = length(var.ui_subnet) == 0 ? azurerm_lb.re-ui-lb-external[0].id : azurerm_lb.re-ui-lb-internal[0].id
  name                = "probe-port-8443"
  port                = 8443
}

resource "azurerm_lb_rule" "re-ui-lb-rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = length(var.ui_subnet) == 0 ? azurerm_lb.re-ui-lb-external[0].id : azurerm_lb.re-ui-lb-internal[0].id
  name                           = "${var.name}-re-ui-lb-rule"
  protocol                       = "tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  frontend_ip_configuration_name = "${var.name}-re-ui-lb-fe-ip"
  load_distribution              = "SourceIP"
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.re-ui-pool.id ]
  probe_id                       = azurerm_lb_probe.re-ui-lb-probe.id
}