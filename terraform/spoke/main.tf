resource "azurerm_resource_group" "mega" {
  name     = "mega-${local.resource_suffix}"
  location = data.azurerm_virtual_hub.mega.location
}

resource "azurerm_virtual_network" "mega" {
  name                = "${azurerm_resource_group.mega.name}-network"
  resource_group_name = azurerm_resource_group.mega.name
  location            = azurerm_resource_group.mega.location
  address_space       = var.address_space
}

resource "azurerm_virtual_hub_connection" "mega" {
  name                      = terraform.workspace
  provider                  = azurerm.hub
  virtual_hub_id            = data.azurerm_virtual_hub.mega.id
  remote_virtual_network_id = azurerm_virtual_network.mega.id
  internet_security_enabled = true
}

module "cluster" {
  source               = "./modules/cluster"
  resource_group_name  = azurerm_resource_group.mega.name
  virtual_network_name = azurerm_virtual_network.mega.name

  depends_on = [
    azurerm_resource_group.mega,
    azurerm_virtual_network.mega
  ]
}

resource "kubernetes_manifest" "gateway_api_crd" {
  for_each = local.gateway_api_crds
  manifest = { for key, value in yamldecode(data.http.gateway_api_crd[each.key].response_body) : key => value if key != "status" }

  depends_on = [
    module.cluster
  ]
}

resource "helm_release" "cilium" {
  name             = "cilium"
  repository       = "https://helm.cilium.io"
  chart            = "cilium"
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  reuse_values     = true
  version          = var.cilium_version

  set {
    name  = "aksbyocni.enabled"
    value = "true"
  }

  set {
    name  = "nodeinit.enabled"
    value = "true"
  }

  set {
    name  = "envoy.enabled"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enabled"
    value = "true"
  }

  set {
    name  = "encryption.enabled"
    value = "true"
  }

  set {
    name  = "encryption.type"
    value = "wireguard"
  }

  set {
    name  = "encryption.nodeEncryption"
    value = "true"
  }

  set {
    name  = "encryption.nodeEncryption"
    value = "true"
  }

  set {
    name  = "ingressController.enabled"
    value = "true"
  }

  set {
    name  = "kubeProxyReplacement"
    value = "strict"
  }

  set {
    name  = "authentication.mutual.spire.enabled"
    value = "false"
  }

  set {
    name  = "ipv6.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_manifest.gateway_api_crd
  ]
}
