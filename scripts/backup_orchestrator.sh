#!/bin/bash
set -e

# --- Configuration ---
# Mettez ici le user et les IPs/noms DNS de vos LXC
USER="clem"
LXC_ADGUARD="192.168.1.40"
LXC_NGINX="192.168.1.42"
LXC_SERVARR="localhost" # Le script tourne ici, donc on utilise localhost

# Dossier racine des projets DANS chaque LXC
PROJECTS_ROOT="/docker/servarr" # Adaptez si le chemin est différent dans les autres LXC

# Dossier de destination pour la sauvegarde FINALE sur ce LXC
BACKUP_DEST="/media/backup"

# Dossier de travail temporaire sur ce LXC pour rassembler les fichiers
TEMP_BACKUP_DIR="${BACKUP_DEST}/tmp"

# Nom du fichier de sauvegarde
DATE=$(date +"%Y-%m-%d")
BACKUP_FILENAME="homelab-backup-${DATE}.tar.gz"
BACKUP_FULL_PATH="${BACKUP_DEST}/${BACKUP_FILENAME}"

# --- Début du Script ---
echo "--- Lancement du script de sauvegarde orchestré ---"

# Créer les dossiers de travail s'ils n'existent pas
mkdir -p "${TEMP_BACKUP_DIR}"
mkdir -p "${BACKUP_DEST}"

# Fonction pour arrêter les services sur un LXC distant
stop_services() {
    echo "Arrêt des services sur $1..."
    ssh "${USER}@$1" "cd ${PROJECTS_ROOT}/$2 && docker-compose down"
}

# Fonction pour démarrer les services sur un LXC distant
start_services() {
    echo "Démarrage des services sur $1..."
    ssh "${USER}@$1" "cd ${PROJECTS_ROOT}/$2 && docker-compose up -d"
}

# 1. Arrêter TOUS les services pour garantir la cohérence des données
stop_services "$LXC_ADGUARD" "lxc-100-adguard"
stop_services "$LXC_NGINX" "lxc-101-nginx-proxy-manager"
stop_services "$LXC_SERVARR" "lxc-103-servarr-stack"

# 2. Copier toutes les données vers le dossier temporaire local via rsync
echo "Copie des données vers le nœud de gestion..."
# rsync -a: mode archive (préserve permissions, etc.), -z: compresse pendant le transfert
rsync -az "${USER}@${LXC_ADGUARD}:${PROJECTS_ROOT}/lxc-100-adguard/" "${TEMP_BACKUP_DIR}/lxc-100-adguard/"
rsync -az "${USER}@${LXC_NGINX}:${PROJECTS_ROOT}/lxc-101-nginx-proxy-manager/" "${TEMP_BACKUP_DIR}/lxc-101-nginx-proxy-manager/"
rsync -az "${PROJECTS_ROOT}/lxc-103-servarr-stack/" "${TEMP_BACKUP_DIR}/lxc-103-servarr-stack/" # Copie locale

# 3. Créer l'archive finale à partir du dossier temporaire
echo "Création de l'archive ${BACKUP_FILENAME}..."
# On se place dans le dossier temporaire pour que les chemins dans l'archive soient relatifs
tar -czf "${BACKUP_FULL_PATH}" -C "${TEMP_BACKUP_DIR}" .

# 4. Redémarrer TOUS les services (même si la sauvegarde a échoué, on veut que les services remontent)
# Utilisation d'un 'trap' pour garantir le redémarrage serait encore mieux, mais restons simples pour l'instant.
start_services "$LXC_ADGUARD" "lxc-100-adguard"
start_services "$LXC_NGINX" "lxc-101-nginx-proxy-manager"
start_services "$LXC_SERVARR" "lxc-103-servarr-stack"

# 5. Nettoyer le dossier temporaire
echo "Nettoyage du dossier temporaire..."
rm -rf "${TEMP_BACKUP_DIR}"

# 6. Nettoyer les anciennes sauvegardes
echo "Nettoyage des sauvegardes de plus de 7 jours..."
find "${BACKUP_DEST}" -name "homelab-backup-*.tar.gz" -mtime +7 -exec rm {} \;

echo "--- Script de sauvegarde terminé avec succès ---"
