output "host" {
  value = azurerm_kubernetes_cluster.mega.kube_config.0.host
}

output "cluster_ca_certificate" {
  value = base64decode(azurerm_kubernetes_cluster.mega.kube_config.0.cluster_ca_certificate)
}