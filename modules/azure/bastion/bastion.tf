# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Create public IP for bastion node
resource "azurerm_public_ip" "bastion-public-ip" {
    name                         = "${var.name}-bastion-public-ip"
    location                     = var.region
    resource_group_name          = var.resource_group
    allocation_method            = "Dynamic"

    tags = {
        environment = "${var.name}"
    }
}

# Create network interface for bastion node
resource "azurerm_network_interface" "bastion-nic" {
    name                      = "${var.name}-bastion-nic"
    location                  = var.region
    resource_group_name       = var.resource_group

    ip_configuration {
        name                          = "${var.name}-bastion-nic-configuration"
        subnet_id                     = var.public_subnet_id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.bastion-public-ip.id
    }

    tags = {
        environment = "${var.name}"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "public-nic" {
    network_interface_id      = azurerm_network_interface.bastion-nic.id
    network_security_group_id = var.public_secgroup[0]
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.resource_group
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = var.resource_group
    location                    = var.region
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "${var.name}"
    }
}

# Create bastion node
resource "azurerm_linux_virtual_machine" "bastion" {
    name                  = "${var.name}-bastion"
    location              = var.region
    resource_group_name   = var.resource_group
    network_interface_ids = [azurerm_network_interface.bastion-nic.id]
    size                  = var.bastion_machine_type

    os_disk {
      name                 = "${var.name}-bastion_os_disk"
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    source_image_reference {
      publisher = split(":", var.os)[0]
      offer     = split(":", var.os)[1]
      sku       = split(":", var.os)[2]
      version   = split(":", var.os)[3]
    }

    plan {
      name      = split(":", var.os)[2]
      product   = split(":", var.os)[1]
      publisher = split(":", var.os)[0]     
    }

    computer_name  = "bastion"
    admin_username = var.ssh_user
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.ssh_user
        public_key     = file(var.ssh_pub_key_file)
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "${var.name}"
    }
    
}