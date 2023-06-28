output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "cluster_rg" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "cluster_identities" {
  value = azurerm_kubernetes_cluster.aks.identity
}

output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
}

output "username" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.username
}

output "password" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config.0.password
  sensitive = true
}

output "client_ertificate_b64" {
  value = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  sensitive = true
}

output "client_key_b64" {
  value = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  sensitive = true
}

output "cluster_ca_cert_b64" {
  value = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
  sensitive = true
}