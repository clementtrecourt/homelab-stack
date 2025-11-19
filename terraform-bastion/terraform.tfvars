proxmox_api_url         = "https://192.168.1.50:8006/api2/json"
proxmox_api_token_id    = "ansible-api@pve!terraform"
proxmox_api_token_secret = "05699295-8be8-4d92-873a-35a731fa95a9"


lxc_template            = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst" # Change to your desired template
root_password           = "clement2509"
ssh_public_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlqpwvoQkYtfMypZCMGD8lisEZQxDq7fx01Jhc0urFV clement@hp-dev"echo "--- 3. Ansible Apply ---"
cd ../ansible

# Activer l'environnement virtuel avant de lancer la commande
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
else
    echo "ERREUR: L'environnement virtuel .venv n'existe pas !"
    exit 1
fi

# Lancer Ansible (depuis le venv)
ansible-playbook site.yml --vault-password-file /home/clem/homelab/ansible/.vault_pass