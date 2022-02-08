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
