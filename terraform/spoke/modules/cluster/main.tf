resource "azurerm_subnet" "cluster_api" {
  name                 = "${data.azurerm_virtual_network.mega.name}-subnet-cluster-api"
  resource_group_name  = data.azurerm_resource_group.mega.name
  virtual_network_name = data.azurerm_virtual_network.mega.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.0, 8, 0),
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.1, 4, 0)
  ]

  delegation {
    name = "managedClusters"

    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "cluster_nodes_agent" {
  name                 = "${data.azurerm_virtual_network.mega.name}-subnet-cluster-nodes-agent"
  resource_group_name  = data.azurerm_resource_group.mega.name
  virtual_network_name = data.azurerm_virtual_network.mega.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.0, 8, 1),
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.1, 4, 1)
  ]
}

resource "azurerm_subnet" "cluster_nodes_workload" {
  for_each             = toset(local.zones)
  name                 = "${data.azurerm_virtual_network.mega.name}-subnet-cluster-nodes-workload-zone-${each.key}"
  resource_group_name  = data.azurerm_resource_group.mega.name
  virtual_network_name = data.azurerm_virtual_network.mega.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.0, 8, 2 + index(tolist(local.zones), each.key)),
    cidrsubnet(data.azurerm_virtual_network.mega.address_space.1, 4, 2 + index(tolist(local.zones), each.key))
  ]
}

resource "azurerm_public_ip_prefix" "nat_gateway" {
  for_each            = toset(local.zones)
  name                = "${data.azurerm_resource_group.mega.name}-nat-gateway-ip-prefix-zone-${each.key}"
  resource_group_name = data.azurerm_resource_group.mega.name
  location            = data.azurerm_resource_group.mega.location
  prefix_length       = 28
  zones               = [each.key]
  sku                 = "Standard"
  ip_version          = "IPv4"
}

resource "azurerm_public_ip_prefix" "load_balancer" {
  for_each            = local.ip_versions
  name                = "${data.azurerm_resource_group.mega.name}-load-balancer-ip-prefix-${trimprefix(each.key, "IP")}"
  resource_group_name = data.azurerm_resource_group.mega.name
  location            = data.azurerm_resource_group.mega.location
  prefix_length       = each.value
  zones               = local.zones
  sku                 = "Standard"
  ip_version          = each.key
}

resource "azurerm_nat_gateway" "cluster" {
  for_each                = toset(local.zones)
  name                    = "${data.azurerm_resource_group.mega.name}-nat-gateway-zone-${each.key}"
  resource_group_name     = data.azurerm_resource_group.mega.name
  location                = data.azurerm_resource_group.mega.location
  idle_timeout_in_minutes = 30
  zones                   = [each.key]
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "cluster" {
  for_each            = toset(local.zones)
  nat_gateway_id      = azurerm_nat_gateway.cluster[each.key].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_gateway[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "cluster" {
  for_each       = toset(local.zones)
  subnet_id      = azurerm_subnet.cluster_nodes_workload[each.key].id
  nat_gateway_id = azurerm_nat_gateway.cluster[each.key].id
}

resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${data.azurerm_resource_group.mega.name}-identity-cluster"
  resource_group_name = data.azurerm_resource_group.mega.name
  location            = data.azurerm_resource_group.mega.location
}

resource "azurerm_role_assignment" "cluster_network_contributor" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  scope                = data.azurerm_virtual_network.mega.id
}

resource "azurerm_kubernetes_cluster" "mega" {
  name                              = "${data.azurerm_resource_group.mega.name}-cluster"
  resource_group_name               = data.azurerm_resource_group.mega.name
  location                          = data.azurerm_resource_group.mega.location
  dns_prefix                        = terraform.workspace
  kubernetes_version                = var.kubernetes_version
  local_account_disabled            = true
  node_os_channel_upgrade           = "None"
  node_resource_group               = "${data.azurerm_resource_group.mega.name}-cluster"
  oidc_issuer_enabled               = true
  role_based_access_control_enabled = true
  sku_tier                          = "Free"
  workload_identity_enabled         = true

  api_server_access_profile {
    vnet_integration_enabled = true
    subnet_id                = azurerm_subnet.cluster_api.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = false
    admin_group_object_ids = ["225b05d2-33ca-4c4e-9224-f2aed8b54f88"]
  }

  default_node_pool {
    name                         = "agentpool"
    enable_auto_scaling          = true
    min_count                    = 1
    max_count                    = 8
    max_pods                     = 40
    only_critical_addons_enabled = true
    os_disk_size_gb              = 32
    vm_size                      = "Standard_D8s_v5"
    vnet_subnet_id               = azurerm_subnet.cluster_nodes_agent.id
    zones                        = local.zones
  }

  network_profile {
    network_plugin    = "none"
    ip_versions       = ["IPv4", "IPv6"]
    load_balancer_sku = "standard"

    load_balancer_profile {
      idle_timeout_in_minutes = 4
      outbound_ip_prefix_ids  = [for key, value in local.ip_versions : azurerm_public_ip_prefix.load_balancer[key].id]
    }
  }

  depends_on = [
    azurerm_role_assignment.cluster_network_contributor
  ]

  lifecycle {
    ignore_changes = [
      microsoft_defender
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  for_each              = toset(local.zones)
  name                  = "workload${each.key}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.mega.id
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 4
  max_pods              = 40
  os_disk_size_gb       = 64
  vm_size               = "Standard_D8s_v5"
  vnet_subnet_id        = azurerm_subnet.cluster_nodes_workload[each.key].id
  zones                 = [each.key]
}
