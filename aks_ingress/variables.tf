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