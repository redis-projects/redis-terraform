# Creating the security groups

# Create Network Security Group and rule
resource "azurerm_network_security_group" "allow-ssh" {
    name                = "${var.name}-allow-ssh"
    location            = var.region
    resource_group_name = var.resource_group
    tags = {
        environment = "${var.name}"
    }
}

resource "azurerm_network_security_group" "allow-local" {
    name                = "${var.name}-allow-local"
    location            = var.region
    resource_group_name = var.resource_group
    tags = {
        environment = "${var.name}"
    }
}

 resource "azurerm_network_security_rule" "public-ssh" {
    name                        = "${var.name}-public-SSH"
    priority                    = 1001
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-ssh.name
}

resource "azurerm_network_security_rule" "public-outgoing" {
    name                        = "${var.name}-public-outgoing"
    priority                    = 1002
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-ssh.name
}

resource "azurerm_network_security_rule" "grafana" {
    name                        = "${var.name}-grafana"
    priority                    = 1003
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "3000"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-ssh.name
}

resource "azurerm_network_security_rule" "private-incoming" {
    name                        = "${var.name}-private-incoming"
    priority                    = 1101
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = var.vpc_cidr
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-local.name
}

resource "azurerm_network_security_rule" "private-dns" {
    name                        = "${var.name}-private-dns"
    priority                    = 1102
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Udp"
    source_port_range           = "*"
    destination_port_range      = "53"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-local.name
}

resource "azurerm_network_security_rule" "Redis-GUI" {
    name                        = "${var.name}-GUI-REST-traffic"
    priority                    = 1104
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_ranges     = ["8443", "9443"]
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-local.name
}

resource "azurerm_network_security_rule" "private-outgoing" {
    name                        = "${var.name}-private-outgoing"
    priority                    = 1103
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = var.resource_group
    network_security_group_name = azurerm_network_security_group.allow-local.name
}
