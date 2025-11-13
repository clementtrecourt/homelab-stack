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
  pm_debug            = true
}

locals {
  containers = {
    adguard = {
      vmid = 200
      ip   = "192.168.1.30/24"
      cores = 1
      memory = 512
      swap = 1024
      rootfs_size = "8G" 
    }
    servarr = {
      vmid = 201
      ip   = "192.168.1.32/24"
      cores = 3             
      memory = 2861
      swap = 1024
      rootfs_size = "32G"         
    }
    nginx = {
      vmid = 202
      ip   = "192.168.1.33/24"
      cores = 1
      memory = 512
      swap = 1024
      rootfs_size = "8G" 
    }
  }
}

# 2. Create a SINGLE resource block that loops over your map.
#    Terraform will create one container for each entry in local.containers.
resource "proxmox_lxc" "ct_group" {
  for_each = local.containers

  target_node  = var.proxmox_node
  ostemplate   = var.lxc_template
  # password     = var.root_password
  unprivileged = true
  start        = true
  
  rootfs {
    storage = "local-lvm"
    size    = each.value.rootfs_size
  }
  password = var.root_password
  ssh_public_keys = var.ssh_public_key
  nameserver   = "1.1.1.1" # Or your preferred DNS
  searchdomain = "local"
  network {
    name   = "eth0"
    bridge = "vmbr0"
    gw     = "192.168.1.254"
    ip = each.value.ip
    ip6    = "auto"
  }
  features {
    nesting = true
  }
  # --- Values that are unique for each container ---
  # 'each.key' is the name (e.g., "adguard", "servarr")
  # 'each.value' is the map of attributes for that name
  
  vmid     = each.value.vmid
  hostname = each.key
  tags     = each.key
  cores    = each.value.cores
  memory   = each.value.memory
  swap     = each.value.swap
}

# 3. The output is now much cleaner and automatically updates
#    if you add/remove containers from the locals map.
output "container_details" {
  description = "A map of container details including their IP addresses."
  value = {
    for name, container in proxmox_lxc.ct_group : name => {
      ip = trimsuffix(container.network[0].ip, "/24") # Removes the /24 part for Ansible
    }
  }
  sensitive = true # Mark as sensitive if it contains IPs you want to hide in logs
}

# This resource creates the Ansible inventory file dynamically.
resource "local_file" "ansible_inventory" {
  # The content is generated from the template file and our Terraform data.
  content = templatefile("${path.module}/inventory.tpl", {
    # The 'containers' variable in the template will be populated by this map.
    containers = {
      for name, container in proxmox_lxc.ct_group : name => {
        ip = trimsuffix(container.network[0].ip, "/24")
      }
    },
    # Pass the root password to the template for the ansible_password var.
    root_password = var.root_password
  })
  
  filename = "${path.module}/../ansible/inventory.tf.ini"
}