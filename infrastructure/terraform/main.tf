terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
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
    k3s-worker-1 = { vmid = 301, ip = "192.168.1.41", cores = 2, memory = 2560 }
    k3s-worker-2 = { vmid = 302, ip = "192.168.1.42", cores = 2, memory = 2560 }
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

  features {
    nesting = true
  }

  vmid     = each.value.vmid
  hostname = each.key
  cores    = each.value.cores  # ✅ valid for LXC
  memory   = each.value.memory
}
# --- RESSOURCE VM (K3S) ---
resource "proxmox_vm_qemu" "k3s_cluster" {
  for_each = local.k3s_nodes
  
  # Bloc CPU correct (les cores sont définis ici)
  cpu {
    type    = "host"
    sockets = 1
    cores   = each.value.cores
  }

  name        = each.key
  vmid        = each.value.vmid
  target_node = var.proxmox_node
  clone       = "ubuntu-2204-template"
  full_clone  = true
  
  agent       = 1
  os_type     = "cloud-init"
  
  # SUPPRIMÉ : cores = each.value.cores (Ligne 88 qui causait l'erreur)

  memory      = each.value.memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot            = "scsi0"
    size            = "20G"
    type            = "disk"
    storage         = "local-lvm"
    discard         = true
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=${each.value.ip}/24,gw=192.168.1.254"
  ciuser    = "devops"
  sshkeys   = var.ssh_public_key
  
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
    # On construit un map complet pour le template
    containers = merge(
      { for name, ct in proxmox_lxc.ct_group : name => { 
          ip   = trimsuffix(ct.network[0].ip, "/24")
          vmid = ct.vmid
        } 
      },
      { for name, vm in proxmox_vm_qemu.k3s_cluster : name => { 
          # On utilise coalesce pour éviter les erreurs si l'IP n'est pas encore connue
          ip   = vm.default_ipv4_address != "" ? vm.default_ipv4_address : "IP_A_VENIR"
          vmid = vm.vmid
        } 
      }
    ),
    root_password = var.root_password
  })
  filename = "${path.module}/../ansible/inventory.tf.ini"
}