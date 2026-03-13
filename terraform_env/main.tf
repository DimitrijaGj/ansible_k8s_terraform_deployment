terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.61"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

locals {
  types = {
    small = {
      cpu_cores = 2
      cpu_type  = "host"
      mem_mb    = 2048
      disk_gb   = 32
    }

    medium = {
      cpu_cores = 4
      cpu_type  = "host"
      mem_mb    = 4096
      disk_gb   = 50
    }

    large = {
      cpu_cores = 8
      cpu_type  = "host"
      mem_mb    = 16384
      disk_gb   = 100
    }
  }
  choice = local.types[var.vm_type]
  vm_nodes = [
    for index in range(var.vm_count) : {
      name  = format("%s-%02d", var.vm_name_prefix, index + 1)
      ip    = var.vm_ips[index]
      vm_id = var.vm_id_start == null ? null : var.vm_id_start + index
    }
  ]
}

resource "proxmox_virtual_environment_vm" "template-machine" {
  count     = var.vm_count
  node_name = "gjoshevi"
  vm_id     = local.vm_nodes[count.index].vm_id
  name      = local.vm_nodes[count.index].name

  cpu {
    cores = local.choice.cpu_cores
    type  = local.choice.cpu_type
  }

  memory {
    dedicated = local.choice.mem_mb
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = local.choice.disk_gb
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
  }

  clone {
    vm_id = var.template_id
    full  = true
  }
  initialization {
    interface = "ide2"
    type      = "nocloud"
    dns {
      servers = [var.vm_dns_server]
    }

    ip_config {
      ipv4 {
        address = "${local.vm_nodes[count.index].ip}/${var.vm_cidr}"
        gateway = var.vm_gateway
      }
    }

    user_account {
      username = var.ansible_user
      keys     = var.ansible_public_key == null ? [] : [var.ansible_public_key]
    }
  }
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [vms]
    %{for node in local.vm_nodes~}
    ${node.name} ansible_host=${node.ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.ansible_private_key_file}
    %{endfor~}
  EOT
  filename = "${path.module}/../ansible/inventory.ini"

  depends_on = [proxmox_virtual_environment_vm.template-machine]
}

resource "null_resource" "wait_for_ssh" {
  count = var.run_ansible ? 1 : 0

  triggers = {
    vm_ips                   = join(",", var.vm_ips)
    ansible_user             = var.ansible_user
    ansible_private_key_file = var.ansible_private_key_file
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible vms -i ${path.module}/../ansible/inventory.ini -m wait_for_connection -a 'timeout=600 sleep=10 connect_timeout=5'"
  }

  depends_on = [
    proxmox_virtual_environment_vm.template-machine,
    local_file.ansible_inventory
  ]
}

resource "null_resource" "ansible_provision" {
  count = var.run_ansible ? 1 : 0

  triggers = {
    vm_names                 = join(",", local.vm_nodes[*].name)
    vm_ips                   = join(",", var.vm_ips)
    ansible_user             = var.ansible_user
    ansible_private_key_file = var.ansible_private_key_file
    vm_count                 = tostring(var.vm_count)
    vm_id_start              = tostring(var.vm_id_start)
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/../ansible/inventory.ini ${path.module}/../ansible/playbook.yml"
  }

  depends_on = [
    null_resource.wait_for_ssh,
    local_file.ansible_inventory
  ]
}
