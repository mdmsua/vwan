resource "azurerm_virtual_wan" "mega" {
  name                              = "mega-wan"
  resource_group_name               = "mega-global"
  location                          = "westeurope"
  type                              = "Standard"
  allow_branch_to_branch_traffic    = false
  disable_vpn_encryption            = false
  office365_local_breakout_category = "None"
}
