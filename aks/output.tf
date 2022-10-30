output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_registry" {
  value = azurerm_container_registry.acr.login_server
}

output "asks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

resource "local_file" "kubeconfig" {
  depends_on = [ azurerm_kubernetes_cluster.aks ]
  filename = "kubeconfig"
  content = azurerm_kubernetes_cluster.aks.kube_config_raw
}