# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

data "azurerm_dns_zone" "parent" {
  name                = "${var.parent_zone}"
  resource_group_name = var.resource_group
}

resource "azurerm_dns_a_record" "A-records" {
  name                = replace("node${count.index+1}.${var.cluster_fqdn}", ".${data.azurerm_dns_zone.parent.name}", "")
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = var.resource_group
  ttl                 = 60
  records             = [ tostring(var.ip_addresses[count.index].ip_address) ]
  count               = length(var.ip_addresses)
  tags                = "${var.resource_tags}"
}

resource "azurerm_dns_ns_record" "NS-record" {
  name                = replace("${var.cluster_fqdn}", ".${data.azurerm_dns_zone.parent.name}", "")
  zone_name           = data.azurerm_dns_zone.parent.name
  resource_group_name = var.resource_group
  ttl                 = 60
  records             = formatlist("%s.%s",tolist(azurerm_dns_a_record.A-records.*.name),"${data.azurerm_dns_zone.parent.name}")
  tags                = "${var.resource_tags}"
}
