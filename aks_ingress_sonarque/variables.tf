variable "project_name_prefix" {
  default = "wlopezob"
  type = string
  description = "Prefix project name"
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "node_count" {
  type = number
}

variable "custom_domain" {
  type        = string
  description = "Dominio personalizado"
}

variable "subdomain_app_aks" {
  type        = string
  description = "SubDominio de las aplicaciones de aks"
}

## instance sonarqube
variable "user_vm_sq" {
  type        = string
  description = "Usuario de VM de sonarqube"
}

variable "subdomain_sonarqube" {
  type        = string
  description = "SubDominio de sonarqube"
}