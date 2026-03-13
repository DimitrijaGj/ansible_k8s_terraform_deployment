![debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white) ![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![ansible](https://img.shields.io/badge/Ansible-000000?style=for-the-badge&logo=ansible&logoColor=white) ![docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white) ![k8s](https://img.shields.io/badge/Kubernetes-3069DE?style=for-the-badge&logo=kubernetes&logoColor=white)

This folder contains the Ansible deployment used to prepare Debian VMs for Kubernetes.
The playbook targets hosts in the `vms` inventory group and applies the `docker_k8s` role.

## What it does

The role performs the following configuration on each VM:

- updates the APT cache and installs required base packages
- disables swap for Kubernetes compatibility
- loads `overlay` and `br_netfilter` kernel modules
- applies Kubernetes networking `sysctl` settings
- adds the Docker and Kubernetes APT repositories
- installs Docker, containerd, `kubeadm`, `kubelet`, and `kubectl`
- holds Kubernetes packages to prevent unintended upgrades
- enables and starts the `docker` and `containerd` services
- adds the SSH user to the `docker` group

It also includes a Debian Trixie-specific workaround for the APT sequoia policy.

## Files

- `playbook.yml` runs the `docker_k8s` role on the `vms` host group
- `ansible.cfg` points Ansible to `./inventory.ini` and disables host key checking
- `roles/docker_k8s/defaults/main.yml` contains default variables
- `roles/docker_k8s/tasks/main.yml` contains the provisioning steps

## Default variables

```yaml
kubernetes_version: "1.30"
kubernetes_packages:
  - kubelet
  - kubeadm
  - kubectl
vm_dns_server: "1.1.1.1"
```

You can override these with inventory variables, host vars, group vars, or `--extra-vars`.

## Inventory

The playbook expects an inventory group named `vms`.

Example `inventory.ini`:

```ini
[vms]
k8s-node-01 ansible_host=192.168.1.50 ansible_user=k8s-test ansible_ssh_private_key_file=~/.ssh/proxmox_k8s_tf
k8s-node-02 ansible_host=192.168.1.51 ansible_user=k8s-test ansible_ssh_private_key_file=~/.ssh/proxmox_k8s_tf
k8s-node-03 ansible_host=192.168.1.52 ansible_user=k8s-test ansible_ssh_private_key_file=~/.ssh/proxmox_k8s_tf
```

When you run the Terraform deployment from `terraform_env/`, this file is generated automatically as `ansible/inventory.ini`.

## Usage

Run the playbook manually from this folder:

```bash
ansible-playbook playbook.yml
```

Or run it with an explicit inventory file:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Example with overridden variables:

```bash
ansible-playbook -i inventory.ini playbook.yml \
  --extra-vars "kubernetes_version=1.30 vm_dns_server=1.1.1.1"
```

## Terraform integration

If you use the Terraform code in `terraform_env/`, the workflow is:

1. create Debian VMs on Proxmox
2. generate `ansible/inventory.ini`
3. wait for SSH to become reachable
4. run `ansible-playbook ../ansible/playbook.yml`

To provision infrastructure only and skip the Ansible run:

```bash
terraform apply \
  -var="vm_type=small" \
  -var='vm_ips=["192.168.1.50","192.168.1.51","192.168.1.52"]' \
  -var="run_ansible=false"
```
