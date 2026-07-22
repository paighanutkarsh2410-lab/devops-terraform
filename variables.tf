variable "subscription_id" {
  description = "Subscription ID for deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the VM exists"
  type        = string
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual machine"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "os_disk_name" {
  description = "OS disk name in the VM model"
  type        = string
}

variable "network_interface_name" {
  description = "Name of the network interface to create and attach"
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name"
  type        = string
}