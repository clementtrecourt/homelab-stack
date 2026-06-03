terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_parallel         = 1
  pm_timeout          = 600
}

locals {
  # --- CONTENEURS (LXC) ---
  utility_containers = {
    # traefik    = { vmid = 200, ip = "192.168.1.30/24", cores = 1, memory = 512,  rootfs_size = "8G" }
    # servarr    = { vmid = 201, ip = "192.168.1.31/24", cores = 3, memory = 2861, rootfs_size = "32G" }
    # adguard    = { vmid = 202, ip = "192.168.1.32/24", cores = 1, memory = 512,  rootfs_size = "8G" }
    # monitoring = { vmid = 204, ip = "192.168.1.34/24", cores = 2, memory = 2048, rootfs_size = "15G" }
    # identity   = { vmid = 205, ip = "192.168.1.35/24", cores = 2, memory = 2048, rootfs_size = "10G" }
  }

  # --- KUBERNETES (VMs) ---
  k3s_nodes = {
    k3s-master   = { vmid = 300, ip = "192.168.1.40", cores = 2, memory = 4096 }
    k3s-worker-1 = { vmid = 301, ip = "192.168.1.41", cores = 2, memory = 5120 }
    k3s-worker-2 = { vmid = 302, ip = "192.168.1.42", cores = 2, memory = 5120 }
  }
}

# --- RESSOURCE LXC ---
resource "proxmox_lxc" "ct_group" {
  for_each = local.utility_containers

  target_node  = var.proxmox_node
  ostemplate   = var.lxc_template
  unprivileged = true
  start        = true
  onboot       = true
  rootfs {
    storage = "local-lvm"
    size    = each.value.rootfs_size
  }

  password        = var.root_password
  ssh_public_keys = var.ssh_public_key

  network {
    name   = "eth0"
    bridge = "vmbr0"
    gw     = "192.168.1.254"
    ip     = each.value.ip
  }
  nameserver = "8.8.8.8"
  features {
    nesting = true
  }

  vmid     = each.value.vmid
  hostname = each.key
  cores    = each.value.cores # ✅ valid for LXC
  memory   = each.value.memory
}
# --- RESSOURCE VM (K3S) ---
resource "proxmox_vm_qemu" "k3s_cluster" {
  for_each = local.k3s_nodes

  name        = each.key
  vmid        = each.value.vmid
  target_node = var.proxmox_node

  clone      = "ubuntu-2404-k3s-template"
  full_clone = true

  # 1. FORCE UEFI & AGENT
  bios    = "ovmf"
  machine = "q35"
  agent   = 1

  disk {
    slot    = "virtio0"
    size    = "32G"
    type    = "disk"
    storage = "local-lvm"
    discard = true
  }
  serial {
    id = 0
  }
  # 3. Disque EFI pour le boot
  efidisk {
    efitype = "4m"
    storage = "local-lvm"
  }
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "local-lvm"
  }

  # 4. Ordre de boot
  boot = "order=virtio0"

  # 5. Configuration Cloud-Init
  os_type   = "cloud-init"
  ipconfig0 = "ip=${each.value.ip}/24,gw=192.168.1.254"
  ciuser    = "devops"
  sshkeys   = var.ssh_public_key

  # AJOUT DU SCRIPT K3S (Manquant dans ton config)
  cicustom  = "vendor=local:snippets/k3s-prep.yaml"
  ciupgrade = true

  nameserver = "1.1.1.1 8.8.8.8"
  skip_ipv6  = true
  # Hardware
  cpu {
    type    = "host"
    sockets = 1
    cores   = each.value.cores
  }
  memory = each.value.memory
  scsihw = "virtio-scsi-pci"
  vga {
    type = "std"
  }
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  force_create = true
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# --- OUTPUTS ---
output "container_ips" {
  value = { for k, v in proxmox_lxc.ct_group : k => v.network[0].ip }
}

output "vm_ips" {
  value = { for k, v in proxmox_vm_qemu.k3s_cluster : k => v.default_ipv4_address }
}


# --- GENERATION INVENTAIRE ANSIBLE ---
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    containers = merge(
      { for name, ct in proxmox_lxc.ct_group : name => {
        ip   = try(trimsuffix(ct.network[0].ip, "/24"), "IP_LXC_A_VENIR")
        vmid = ct.vmid
        }
      },
      { for name, vm in proxmox_vm_qemu.k3s_cluster : name => {
        # On essaie d'abord l'IP rapportée par l'agent, 
        # sinon on prend l'IP que l'on a définie dans local.k3s_nodes
        ip   = (vm.default_ipv4_address != null && vm.default_ipv4_address != "") ? vm.default_ipv4_address : local.k3s_nodes[name].ip
        vmid = vm.vmid
        }
      }
    ),
    root_password = var.root_password
  })
  filename = "${path.module}/../ansible/inventory.tf.ini"
}
