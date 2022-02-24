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
