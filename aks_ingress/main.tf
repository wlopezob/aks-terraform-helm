resource "azurerm_resource_group" "rg" {
  name = "${var.project_name_prefix}_rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name = "${var.project_name_prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.location
  sku = "Basic"
  admin_enabled = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  node_resource_group = "${azurerm_resource_group.rg.name}_node"
  name = "${var.project_name_prefix}_aks"
  kubernetes_version = var.kubernetes_version
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "${var.project_name_prefix}dns"
  tags = {
    Enviroment = "Dev"
  }
  default_node_pool {
    name = "agentpool"
    node_count = var.node_count
    vm_size = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  http_application_routing_enabled = false
}

# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  name                =  "${var.project_name_prefix}-publicip"
  location            = azurerm_kubernetes_cluster.aks.location
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  allocation_method   = "Static"
  sku = "Standard"
  sku_tier = "Regional"
}

#Create DNS
resource "azurerm_dns_zone" "dns" {
  name                = var.custom_domain
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "rc" {
  name                = "@"
  zone_name           = azurerm_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1
  records             = ["${azurerm_public_ip.public_ip.ip_address}"]
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

# Install Nginx Ingress using Helm Chart
resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  namespace = "ingress-basic"
  create_namespace = true
  chart      = "./charts/ingress-nginx-4.3.0.tgz" #https://github.com/kubernetes/ingress-nginx/releases
  timeout                 = 600
  reuse_values            = true
  recreate_pods           = true
  cleanup_on_fail         = true
  wait                    = true
  verify                  = false
  set {
    name  = "controller.replicaCount"
    value = var.node_count+ 1
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "${azurerm_public_ip.public_ip.ip_address}"
  }
}