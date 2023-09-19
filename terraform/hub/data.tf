data "terraform_remote_state" "wan" {
  backend = "azurerm"
  config = {
    tenant_id            = var.state_tenant_id
    subscription_id      = var.state_subscription_id
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "wanenv:${var.environment}"
    use_azuread_auth     = true
  }
}

data "azurerm_virtual_wan" "mega" {
  provider            = azurerm.wan
  name                = data.terraform_remote_state.wan.outputs.wan_name
  resource_group_name = data.terraform_remote_state.wan.outputs.wan_resource_group_name
}
