proxmox_api_url         = "https://100.101.186.10:8006/api2/json"
proxmox_api_token_id    = "ansible-api@pve!terraform"
proxmox_api_token_secret = "05699295-8be8-4d92-873a-35a731fa95a9"


lxc_template            = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst" # Change to your desired template
root_password           = "clement2509"
ssh_public_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlqpwvoQkYtfMypZCMGD8lisEZQxDq7fx01Jhc0urFV clement@hp-dev"