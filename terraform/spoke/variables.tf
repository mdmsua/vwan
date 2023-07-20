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

variable "state_key_hub" {
  type    = string
  default = "hub.tfstate"
}

variable "address_space" {
  type = string
}

variable "hub_tenant_id" {
  type = string
}

variable "hub_subscription_id" {
  type = string
}
