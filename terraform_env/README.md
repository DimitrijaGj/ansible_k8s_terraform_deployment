![debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white) ![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white)![terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)

This template creates Debian VMs on Proxmox with Terraform and then configures them with Ansible.
It can be used to create three sizes of machines:
- small
- medium
- large

## Usage

```bash
terraform apply \
  -var="vm_type=small" \
  -var='vm_ips=["192.168.1.50","192.168.1.51","192.168.1.52"]' \
  -var="vm_gateway=192.168.1.1" \
  -var="ansible_user=debian" \
  -var='ansible_public_key=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your@host' \
  -var="ansible_private_key_file=~/.ssh/id_rsa"
```

By default this creates `3` VMs named `k8s-node-01`, `k8s-node-02`, and `k8s-node-03`.

After the VMs are created, Terraform will:
1. Generate `../ansible/inventory.ini`
2. Wait until SSH is reachable on all VMs
3. Run `ansible-playbook ../ansible/playbook.yml`
4. Install Docker, `kubeadm`, `kubelet`, and `kubectl` on all nodes

To skip Ansible auto-provisioning:

```bash
terraform apply \
  -var="vm_type=small" \
  -var='vm_ips=["192.168.1.50","192.168.1.51","192.168.1.52"]' \
  -var="run_ansible=false"
```
