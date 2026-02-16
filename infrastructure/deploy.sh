#!/bin/bash
set -e

echo "🏗️  1. Provisioning Hardware via Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# ON ALIGNE LE NOM DU FICHIER ICI
INVENTORY="ansible/inventory.tf.ini"

# Vérification que Terraform a bien bossé
if [ ! -f "$INVENTORY" ]; then
    echo "❌ Erreur : $INVENTORY introuvable !"
    exit 1
fi

echo "⏳ 2. Attente du boot des VMs (20s)..."
sleep 30
# Dans ton deploy.sh, après terraform apply
echo "🧹 Nettoyage des anciennes clés SSH..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.40" > /dev/null 2>&1
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.41" > /dev/null 2>&1
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.42" > /dev/null 2>&1
echo "🔧 3. Configuration via Ansible..."
cd ansible
# Utilisation explicite du bon fichier d'inventaire
ansible-playbook -i inventory.tf.ini site.yml
cd ..

echo "🔑 4. Récupération du Kubeconfig..."
# Extraction propre de l'IP depuis inventory.tf.ini
MASTER_IP=$(grep "ansible_host=" "$INVENTORY" | grep "k3s-master" | awk -F'ansible_host=' '{print $2}' | awk '{print $1}')

if [ -z "$MASTER_IP" ]; then
    echo "❌ Erreur : Impossible de trouver l'IP du Master."
    exit 1
fi

echo "📡 Connexion au Master : $MASTER_IP"
mkdir -p ~/.kube
scp -o StrictHostKeyChecking=no devops@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i "s/127.0.0.1/$MASTER_IP/g" ~/.kube/config
chmod 600 ~/.kube/config

echo "✅ Cluster K3s prêt !"
echo "🌐 ArgoCD : https://argocd.clem-ops.org"