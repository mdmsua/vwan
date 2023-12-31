variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "state_tenant_id" {
  type = string
}

variable "state_subscription_id" {
  type = string
}

variable "state_resource_group_name" {
  type = string
}

variable "state_storage_account_name" {
  type = string
}

variable "state_container_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "hub" {
  type = string
}

variable "hub_tenant_id" {
  type = string
}

variable "hub_subscription_id" {
  type = string
}

variable "cilium_version" {
  type    = string
  default = "v1.14"
}

variable "gateway_api_version" {
  type    = string
  default = "v0.8.0"
}
