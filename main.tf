terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.0.0"
    }
  }
}
variable "host_datastore_map" {
  type = map(list(string))
  description = "Map of hosts to their accessible datastores"
  default = {
    "172.28.8.2" = ["Local-2.1"],
    "172.28.8.3" = ["Local-3.0"],
    "172.28.8.4" = ["Local-4.0"]
  }
}
provider "vsphere" {
  user                  = var.vm_username
  password              = var.vm_password
  vsphere_server        = var.vsphere_server
  allow_unverified_ssl  = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "selected_host" {
  name          = var.selected_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  vm_names = [for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : "${var.vm_name_prefix}${idx}"]

  vm_hostnames = {
    for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : local.vm_names[idx - var.vm_start_index] => "${var.vm_hostname_prefix}${idx}"
  }

  vm_ips = [
    for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : cidrhost("${var.ip_base}/24", idx)
  ]

  vm_roles = [
    for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : (idx == var.vm_start_index ? "master" : "worker")
  ]
  accessible_datastores = try(var.host_datastore_map[var.selected_host], [])
}
data "vsphere_datastore" "selected_datastore" {
  count          = length(local.accessible_datastores) > 0 ? 1 : 0
  name           = local.accessible_datastores[0]
  datacenter_id  = data.vsphere_datacenter.dc.id

  # Fail gracefully if the datastore does not exist
  depends_on = [data.vsphere_host.selected_host]
}

output "datastore_id" {
  value = length(data.vsphere_datastore.selected_datastore) > 0 ? data.vsphere_datastore.selected_datastore[0].id : null
}

resource "vsphere_tag_category" "category" {
  name             = "Kubernetes"
  description      = "Category for Kubernetes VMs"
  cardinality      = "MULTIPLE"
  associable_types = ["VirtualMachine"]
}

resource "vsphere_tag" "master" {
  name        = "master"
  description = "Tag for master VMs"
  category_id = vsphere_tag_category.category.id
}

resource "vsphere_tag" "worker" {
  name        = "worker"
  description = "Tag for worker VMs"
  category_id = vsphere_tag_category.category.id
}

resource "vsphere_virtual_machine" "vms" {
  for_each = { for idx, name in local.vm_names : name => idx }

  name             = each.key
  resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.selected_datastore[0].id
  folder           = "Kubernetes"

  num_cpus         = 2
  memory           = 4096
  guest_id         = "ubuntu64Guest"

  disk {
    label            = "disk0"
    size             = "100"
    thin_provisioned = true
  }

  connection {
    type     = "ssh"
    user     = "test"
    password = "Welcome@123"
    host     = self.default_ip_address
  }

  provisioner "file" {
    source      = var.idrsa_pub
    destination = "/tmp/authorized_keys"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.ssh",
      "cat /tmp/authorized_keys >> ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
      "chmod 700 ~/.ssh",
    ]
  }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = local.vm_hostnames[each.key]
        domain    = ""
      }

      network_interface {
        ipv4_address = local.vm_ips[each.value]
        ipv4_netmask = 24
      }

      ipv4_gateway    = var.vm_ipv4_gateway
      dns_server_list = ["8.8.8.8", "8.8.4.4"]
    }
  }
  host_system_id = data.vsphere_host.selected_host.id
  #host_system_id = element(data.vsphere_host.hosts.host_ids, each.value % length(data.vsphere_host.hosts.host_ids))
}

resource "local_file" "inventory" {
  content = join("\n\n", [
    templatefile("inventory.tpl", {
      master_vms              = [for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : local.vm_names[idx - var.vm_start_index] if local.vm_roles[idx - var.vm_start_index] == "master"],
      worker_vms              = [for idx in range(var.vm_start_index, var.vm_start_index + var.vm_count) : local.vm_names[idx - var.vm_start_index] if local.vm_roles[idx - var.vm_start_index] == "worker"],
      vsphere_virtual_machine = vsphere_virtual_machine.vms
    }),
    templatefile("additional_inventory.tpl", {
      idrsa = var.idrsa
    })
  ])

  filename = "ansible/inventory.ini"
}

