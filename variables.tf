variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "vm_start_index" {
  type        = number
  description = "Starting index for VM names, hostnames, and IP addresses"
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names"
}

variable "vm_hostname_prefix" {
  type        = string
  description = "Prefix for VM hostnames"
}

variable "ip_base" {
  type        = string
  description = "Base IP address (e.g., 172.28.8.0) to start assigning IP addresses from"
}

variable "vm_username" {
  type        = string
  description = "Username for vSphere authentication"
}

variable "vm_password" {
  type        = string
  description = "Password for vSphere authentication"
}

variable "vsphere_server" {
  type        = string
  description = "vSphere server address"
}

variable "vsphere_datacenter" {
  type        = string
  description = "vSphere datacenter name"
}

variable "vsphere_compute_cluster" {
  type        = string
  description = "vSphere compute cluster name"
}

variable "vm_ipv4_gateway" {
  type        = string
  description = "IPv4 gateway for VMs"
}

variable "idrsa_pub" {
  type        = string
  description = "Path to id_rsa.pub file"
}

variable "network" {
  type        = string
  description = "Name of the network"
}

variable "template" {
  type        = string
  description = "Name of the VM template"
}
variable "selected_host" {
  description = "Selected ESXi host for VM placement"
  type        = string
}
variable "idrsa" {
  description = "id_rsa key file"
  type        = string
}
variable "idrsa_pub" {
  description = "id_rsa key file"
  type        = string
}

