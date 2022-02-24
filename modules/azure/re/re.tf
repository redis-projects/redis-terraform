# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Create network interface for Redis nodes
resource "azurerm_network_interface" "redis-nic" {
    name                = "${var.name}-redis-${count.index}-nic"
    location            = var.region
    resource_group_name = var.resource_group
    count               = var.machine_count

    ip_configuration {
        name                          = "${var.name}-redis-nic-${count.index}-configuration"
        subnet_id                     = var.private_subnet_id
        private_ip_address_allocation = "Dynamic"
    }

    tags = merge("${var.resource_tags}",{
        environment = "${var.name}"
    })
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

    tags = merge("${var.resource_tags}",{
        environment = "${var.name}"
    })
}

# Create Redis nodes
resource "azurerm_linux_virtual_machine" "redis" {
    name                  = "${var.name}-redis-${count.index}"
    location              = var.region
    resource_group_name   = var.resource_group
    network_interface_ids = [azurerm_network_interface.redis-nic[count.index].id]
    size                  = var.machine_type
    zone                  = sort(var.zones)[count.index % length(var.zones)]
    count                 = var.machine_count

    os_disk {
      name                 = "${var.name}-redis-${count.index}_os_disk"
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    source_image_reference {
      publisher = split(":", var.os)[0]
      offer     = split(":", var.os)[1]
      sku       = split(":", var.os)[2]
      version   = split(":", var.os)[3]
    }

    dynamic "plan" {
      for_each = var.machine_plan == "" ? [] : [1]
      content {
        name      = split(":", var.machine_plan)[0]
        product   = split(":", var.machine_plan)[1]
        publisher = split(":", var.machine_plan)[2]
      }
    }

    computer_name  = "${var.name}-redis-${count.index}"
    admin_username = var.ssh_user
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.ssh_user
        public_key     = file(var.ssh_pub_key_file)
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = merge("${var.resource_tags}",{
        environment = "${var.name}"
    })
}
