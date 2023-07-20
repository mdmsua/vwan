data "azurerm_resource_group" "mega" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "mega" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.mega.name
}
