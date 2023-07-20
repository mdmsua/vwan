resource "azurerm_subnet" "cluster_api" {
  name                 = "${data.azurerm_virtual_network.mega.name}-subnet-cluster-api"
  resource_group_name  = data.azurerm_resource_group.mega.name
  virtual_network_name = data.azurerm_virtual_network.mega.name
  address_prefixes     = [cidrsubnet(data.azurerm_virtual_network.mega.address_space.0, 2, 0)]

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

resource "azurerm_subnet" "cluster_nodes" {
  name                 = "${data.azurerm_virtual_network.mega.name}-subnet-cluster-nodes"
  resource_group_name  = data.azurerm_resource_group.mega.name
  virtual_network_name = data.azurerm_virtual_network.mega.name
  address_prefixes     = [cidrsubnet(data.azurerm_virtual_network.mega.address_space.0, 2, 1)]
}

resource "azurerm_public_ip_prefix" "cluster" {
  name                = "${data.azurerm_resource_group.mega.name}-nat-gateway-ip-prefix"
  resource_group_name = data.azurerm_resource_group.mega.name
  location            = data.azurerm_resource_group.mega.location
  prefix_length       = 28
  zones               = ["1", "2", "3"]
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "cluster" {
  name                    = "${data.azurerm_resource_group.mega.name}-nat-gateway"
  resource_group_name     = data.azurerm_resource_group.mega.name
  location                = data.azurerm_resource_group.mega.location
  idle_timeout_in_minutes = 30
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "cluster" {
  nat_gateway_id      = azurerm_nat_gateway.cluster.id
  public_ip_prefix_id = azurerm_public_ip_prefix.cluster.id
}

resource "azurerm_subnet_nat_gateway_association" "cluster" {
  subnet_id      = azurerm_subnet.cluster_nodes.id
  nat_gateway_id = azurerm_nat_gateway.cluster.id
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
  kubernetes_version                = "1.27.1"
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
    vnet_subnet_id               = azurerm_subnet.cluster_nodes.id
    zones                        = ["1", "2", "3"]
  }

  network_profile {
    network_plugin = "none"
    outbound_type  = "userAssignedNATGateway"
  }

  depends_on = [azurerm_role_assignment.cluster_network_contributor]
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.mega.id
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 4
  max_pods              = 40
  os_disk_size_gb       = 64
  vm_size               = "Standard_D8s_v5"
  vnet_subnet_id        = azurerm_subnet.cluster_nodes.id
  zones                 = ["1", "2", "3"]
}
