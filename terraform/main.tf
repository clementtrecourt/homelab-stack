terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url            = var.proxmox_api_url
  pm_api_token_id       = var.proxmox_api_token_id
  pm_api_token_secret   = var.proxmox_api_token_secret
  pm_tls_insecure       = true
  pm_debug              = true # <--- ADD THIS LINE
}

resource "proxmox_lxc" "nginx" {
  target_node = var.proxmox_node
  vmid          = 104
  hostname      = "nginx"
  ostemplate    = var.lxc_template
  password      = var.root_password
  unprivileged = true

  cores         = 1
  memory        = 512
  swap          = 512

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    gw     = "192.168.1.254"
    ip     = "192.168.1.33/24"
  }

  features {
    nesting = true
  }

  # This will start the container after it's created
  start = true

  # You can add tags to easily identify resources managed by Terraform
  tags = "nginx"
}

# Output the IP address of the created container
output "lxc_ip_address" {
  value = proxmox_lxc.nginx.network[0].ip
}
