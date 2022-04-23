variable "rg_name" {
  description = "Name Resource Group on Azure"
  type        = string
}

variable "location" {
  description = "Location Project on Azure"
  type        = string
}

variable "prefix" {
  description = "Prefix resources"
  type        = string
  default     = "eultengo"
}

variable "vnet_name" {
  description = "Name of Vnet"
  type        = string
}

variable "subnet_name" {
  description = "Name of subnet"
  type        = string

}

variable "nic_name" {
  description = "Name of network interface"
  type        = string
}
variable "public_ip" {
  description = "Name of Public IP"
  type        = string
}

variable "ngs_name" {
  description = "Name of network security group"
  type        = string
}

variable "vm_app_name" {
  description = "Name of VM for Application"
  type        = string
}
