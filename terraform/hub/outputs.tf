output "location" {
  value = azurerm_resource_group.mega.location
}

output "hub_name" {
  value = azurerm_virtual_hub.mega.name
}

output "hub_resource_group_name" {
  value = azurerm_virtual_hub.mega.resource_group_name
}
