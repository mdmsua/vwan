resource "azurerm_resource_group" "mega" {
  name     = "mega-${local.resource_suffix}"
  location = data.azurerm_virtual_wan.mega.location
}

resource "azurerm_virtual_hub" "mega" {
  name                   = "mega-hub-${local.resource_suffix}"
  resource_group_name    = azurerm_resource_group.mega.name
  location               = azurerm_resource_group.mega.location
  address_prefix         = var.address_prefix
  sku                    = "Standard"
  virtual_wan_id         = data.azurerm_virtual_wan.mega.id
  hub_routing_preference = "ExpressRoute"
}
