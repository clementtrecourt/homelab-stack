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
}

resource "proxmox_lxc" "bastion" {
  target_node  = var.proxmox_node
  hostname     = "bastion-admin"
  vmid         = 100              # ID 99 pour le distinguer des autres (100+)
  ostemplate   = var.lxc_template
  unprivileged = true
  
  # Un peu plus de ressources pour faire tourner Ansible/Terraform
  cores        = 2
  memory       = 1024
  swap         = 512
  
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  # Réseau
  network {
    name   = "eth0"
    bridge = "vmbr0"
    gw     = "192.168.1.254"    # Ta gateway
    ip     = "192.168.1.20/24"  # IP Fixe dédiée
    ip6    = "auto"
  }

  # Accès
  password        = var.root_password
  ssh_public_keys = var.ssh_public_key
  
  features {
    nesting = true
  }
  
  # Empêche Terraform de le détruire par erreur à l'avenir !
  lifecycle {
    prevent_destroy = true
  }
}

output "bastion_ip" {
  value = "192.168.1.20"
}
