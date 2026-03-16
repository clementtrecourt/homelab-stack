#!/bin/bash
set -e

echo "🏗️  1. Provisioning Hardware via Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..


INVENTORY="ansible/inventory.tf.ini"


if [ ! -f "$INVENTORY" ]; then
    echo "❌ Erreur : $INVENTORY introuvable !"
    exit 1
fi

wait_for_ssh() {
  local host=$1
  local max_attempts=30  
  local attempt=1

  echo "  ⏳ Attente de $host..."
  while ! ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -o BatchMode=yes \
               devops@$host "exit" 2>/dev/null; do
    if [ $attempt -ge $max_attempts ]; then
      echo "  ❌ $host injoignable après $(( max_attempts * 10 ))s — abandon."
      exit 1
    fi
    echo "  · $host pas encore prêt (tentative $attempt/$max_attempts)..."
    sleep 10
    attempt=$(( attempt + 1 ))
  done
  echo "  ✅ $host est up !"
}

echo "⏳ 2. Attente du boot des VMs..."
wait_for_ssh "192.168.1.40" & PID1=$!
wait_for_ssh "192.168.1.41" & PID2=$!
wait_for_ssh "192.168.1.42" & PID3=$!

wait $PID1 || exit 1
wait $PID2 || exit 1
wait $PID3 || exit 1

echo "🟢 Toutes les VMs sont prêtes."

echo "🧹 Nettoyage des anciennes clés SSH..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.40" > /dev/null 2>&1
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.41" > /dev/null 2>&1
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.1.42" > /dev/null 2>&1
sleep 5s
echo "🔧 3. Configuration via Ansible..."
cd ansible
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

echo "🔑 5. Restauration clé Sealed Secrets..."
kubectl apply -f "/home/clem/homelab-stack/sealed-secrets-master.key"
kubectl rollout restart deployment sealed-secrets -n kube-system
kubectl rollout status deployment sealed-secrets -n kube-system --timeout=60s
echo "✅ Cluster K3s prêt !"
echo "🌐 ArgoCD : https://argocd.clem-ops.org"