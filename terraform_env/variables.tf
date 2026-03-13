variable "proxmox_endpoint" {
  description = "Proxmox API Endpoint"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token" {
  description = "Proxmox API Token"
  type        = string
  sensitive   = true
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "k8s-node"
}

variable "vm_id_start" {
  description = "Optional starting VM ID. If set, each VM will increment from this value."
  type        = number
  nullable    = true
  default     = null
}

variable "vm_count" {
  description = "How many VMs to create"
  type        = number
  default     = 3
}

variable "vm_type" {
  description = "What size of VM we create (small, medium, large)"
  type        = string
  default     = "medium"
  validation {
    condition     = contains(["small", "medium", "large"], var.vm_type)
    error_message = "VM Type must be small, medium or large"
  }
}
variable "template_id" {
  description = "VM ID of the template to clone from"
  type        = number
  default     = 103
}

variable "vm_ips" {
  description = "IP addresses or DNS names of the created VMs used by Ansible"
  type        = list(string)

  validation {
    condition     = length(var.vm_ips) == var.vm_count
    error_message = "The number of vm_ips must match vm_count."
  }
}

variable "vm_gateway" {
  description = "IPv4 gateway configured in cloud-init for all VMs"
  type        = string
  default     = null
  nullable    = true
}

variable "vm_cidr" {
  description = "IPv4 CIDR prefix for the VM addresses"
  type        = number
  default     = 24
}

variable "vm_dns_server" {
  description = "DNS server configured in cloud-init for all VMs"
  type        = string
  default     = "1.1.1.1"
}

variable "ansible_user" {
  description = "SSH user for Ansible"
  type        = string
  default     = "k8s-test"
}

variable "ansible_public_key" {
  description = "SSH public key content injected into the VM with cloud-init"
  type        = string
  default     = null
  nullable    = true
}

variable "ansible_private_key_file" {
  description = "Path to private SSH key used by Ansible"
  type        = string
  default     = "~/.ssh/proxmox_k8s_tf"
}

variable "run_ansible" {
  description = "Run Ansible automatically after Terraform creates VM"
  type        = bool
  default     = true
}
