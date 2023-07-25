resource "azurerm_resource_group" "mega" {
  name     = "mega-${terraform.workspace}"
  location = local.location
}

resource "azurerm_virtual_network" "mega" {
  name                = "${azurerm_resource_group.mega.name}-network"
  resource_group_name = azurerm_resource_group.mega.name
  location            = azurerm_resource_group.mega.location
  address_space       = [var.address_space]
}

resource "azurerm_virtual_hub_connection" "mega" {
  name                      = local.spoke
  provider                  = azurerm.hub
  virtual_hub_id            = data.azurerm_virtual_hub.mega.id
  remote_virtual_network_id = azurerm_virtual_network.mega.id
  internet_security_enabled = true
}

module "cluster" {
  source               = "./modules/cluster"
  resource_group_name  = azurerm_resource_group.mega.name
  virtual_network_name = azurerm_virtual_network.mega.name
}

resource "helm_release" "cilium" {
  name             = "cilium"
  repository       = "https://helm.cilium.io"
  chart            = "cilium"
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "aksbyocni.enabled"
    value = "true"
  }

  set {
    name  = "nodeinit.enabled"
    value = "true"
  }

  depends_on = [
    module.cluster
  ]
}
