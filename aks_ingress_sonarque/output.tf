output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_registry" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_login_user" {
  value = azurerm_container_registry.acr.admin_username
}

output "asks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

resource "local_file" "kubeconfig" {
  depends_on = [ azurerm_kubernetes_cluster.aks ]
  filename = "kubeconfig"
  content = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "dns" {
  value = azurerm_dns_zone.dns.name_servers
}

output "domain" {
  value = azurerm_dns_zone.dns.name
}

#### VM sonarqube
output "sq_public_ip_address" {
  value = azurerm_linux_virtual_machine.sq_vm.public_ip_address
}

resource "local_file" "sq_tls_private_key" {
  filename = "sq_key.pem"
  content = tls_private_key.sq_key_ssh.private_key_pem
}

output "connect_ssh" {
  value = "ssh -i ${local_file.sq_tls_private_key.filename} ${var.user_vm_sq}@${azurerm_linux_virtual_machine.sq_vm.public_ip_address}"
}