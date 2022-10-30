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