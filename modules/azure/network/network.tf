# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Create virtual network
resource "azurerm_virtual_network" "vpc" {
    name                = "${var.resource_name}"
    address_space       = [ var.vpc_cidr ]
    location            = var.region
    resource_group_name = var.resource_group

    tags = {
        environment = "Terraform VPC ${var.name}-vpc"
    }
}

# Create public subnet
resource "azurerm_subnet" "public-subnet" {
    name                 = "${var.name}-public-subnet"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vpc.name
    address_prefixes     = [ var.public_subnet_cidr ]
}

# Create private subnet
resource "azurerm_subnet" "private-subnet" {
    name                 = "${var.name}-private-subnet"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vpc.name
    address_prefixes     = [ var.private_subnet_cidr ]
}

resource "azurerm_subnet" "ui-subnet" {
    count                = length(var.ui_cidr) == 0 ? 0 : 1
    name                 = "${var.name}-ui-subnet"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vpc.name
    address_prefixes     = [ var.ui_cidr ]
}

resource "azurerm_public_ip_prefix" "redis-public-prefix" {
  name                = "${var.name}-redis-public-ip-prefix"
  location            = var.region
  resource_group_name = var.resource_group
  prefix_length       = 30
}

resource "azurerm_nat_gateway" "redis-nat-gateway" {
  name                    = "${var.name}-redis-natgateway"
  location                = var.region
  resource_group_name     = var.resource_group
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "public_ip_nat_association" {
  nat_gateway_id       = azurerm_nat_gateway.redis-nat-gateway.id
  public_ip_prefix_id = azurerm_public_ip_prefix.redis-public-prefix.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet-nat-association" {
  subnet_id      = azurerm_subnet.private-subnet.id
  nat_gateway_id = azurerm_nat_gateway.redis-nat-gateway.id
  depends_on     = [azurerm_subnet.private-subnet]
}

resource "azurerm_subnet_network_security_group_association" "private-net" {
  subnet_id                 = azurerm_subnet.private-subnet.id
  network_security_group_id = azurerm_network_security_group.allow-local.id
  depends_on     = [azurerm_subnet.private-subnet, azurerm_network_security_group.allow-local]
}

resource "azurerm_subnet_network_security_group_association" "public-net" {
  subnet_id                 = azurerm_subnet.public-subnet.id
  network_security_group_id = azurerm_network_security_group.allow-ssh.id
  depends_on     = [azurerm_subnet.public-subnet, azurerm_network_security_group.allow-ssh]
}
