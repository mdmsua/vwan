variable "resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.26.6"
}
