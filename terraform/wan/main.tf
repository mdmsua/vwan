resource "azurerm_resource_group" "mega" {
  name     = local.name
  location = var.location
}

resource "azurerm_virtual_wan" "mega" {
  name                              = "mega-wan-${terraform.workspace}"
  resource_group_name               = azurerm_resource_group.mega.name
  location                          = azurerm_resource_group.mega.location
  type                              = "Standard"
  allow_branch_to_branch_traffic    = false
  disable_vpn_encryption            = false
  office365_local_breakout_category = "None"
}
