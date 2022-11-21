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

resource "azurerm_role_assignment" "role_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
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
  name                = var.subdomain_app_aks
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




#### VM sonarqube

# Create virtual network
resource "azurerm_virtual_network" "network" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                = "${var.project_name_prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "sq_sg" {
  name     = "${var.project_name_prefix}_sq_sg"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "${var.project_name_prefix}_sq_out_sg"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SONARQUBE"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "sq_public_ip" {
  name                =  "${var.project_name_prefix}-sq_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
  sku_tier = "Regional"
}

resource "azurerm_dns_a_record" "sq_rc" {
  name                = var.subdomain_sonarqube
  zone_name           = azurerm_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1
  records             = ["${azurerm_public_ip.sq_public_ip.ip_address}"]
}

resource "azurerm_network_interface" "sq-nic" {
  name                = "${var.project_name_prefix}-sq-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.project_name_prefix}-sq-nic_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sq_public_ip.id
  }
}

# Connect the newtwork security group to the network interface
resource "azurerm_network_interface_security_group_association" "sg_association" {
  network_interface_id      = azurerm_network_interface.sq-nic.id
  #subnet_id = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.sq_sg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "sq_storage_account" {
  name                     = "${var.project_name_prefix}diagstorage"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create SSH key
resource "tls_private_key" "sq_key_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "sq_vm" {
  name                  = "${var.project_name_prefix}-sq-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.sq-nic.id]
  size                  = "Standard_B2s"

  os_disk {
    name                 = "${var.project_name_prefix}-disk_os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version = "latest"
  }

  computer_name                   = "vm-sq"
  admin_username                  = var.user_vm_sq
  disable_password_authentication = true
  custom_data = filebase64("scripts/install_sonarqube.sh")

  admin_ssh_key {
    username   = var.user_vm_sq
    public_key = tls_private_key.sq_key_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.sq_storage_account.primary_blob_endpoint
  }
}