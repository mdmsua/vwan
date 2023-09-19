data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    tenant_id            = var.state_tenant_id
    subscription_id      = var.state_subscription_id
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "hubenv:${var.hub}"
    use_azuread_auth     = true
  }
}

data "azurerm_virtual_hub" "mega" {
  provider            = azurerm.hub
  name                = data.terraform_remote_state.hub.outputs.hub_name
  resource_group_name = data.terraform_remote_state.hub.outputs.hub_resource_group_name
}

data "http" "gateway_api_crd" {
  for_each = local.gateway_api_crds
  url      = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_version}/config/crd/${each.value}"

  request_headers = {
    Accept = "text/plain"
  }
}
