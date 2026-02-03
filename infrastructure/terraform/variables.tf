variable "proxmox_api_url" {
  type        = string
  description = "The URL for the Proxmox API (e.g., https://192.168.1.100:8006/api2/json)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The Proxmox API token ID."
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The Proxmox API token secret."
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox node to create the LXC on."
  default     = "pve"
}

variable "lxc_template" {
  type        = string
  description = "The LXC template to use (e.g., local:vztmpl/debian-11-standard_11.3-1_amd64.tar.gz)."
}

variable "root_password" {
  type        = string
  description = "The root password for the LXC container console."
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to install on the containers for Ansible access."
  sensitive   = true
}