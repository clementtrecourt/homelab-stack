# Stack de Services Média (*arrs, Jellyfin)

Ce dossier contient la configuration Docker Compose pour une stack média complète, automatisée et sécurisée.

## Services Inclus

*   `gluetun` : Client VPN qui crée un tunnel sécurisé pour le trafic sortant.
*   `qbittorrent` : Client BitTorrent.
*   `prowlarr` : Gestionnaire d'indexeurs.
*   `sonarr` : Gestionnaire de séries TV.
*   `radarr` : Gestionnaire de films.
*   `jellyfin` : Serveur média.
*   `jellyseerr` : Système de requêtes et de découverte de médias.
*   `gestionnaire-app` : Application web personnalisée construite à partir d'un Dockerfile local.

## Architecture Réseau

Cette stack utilise une architecture réseau spécifique pour la sécurité :

1.  **Isolation VPN** : `qbittorrent` et `prowlarr` sont configurés avec `network_mode: service:gluetun`. Tout leur trafic réseau passe **exclusivement** par le conteneur `gluetun`, garantissant qu'aucune donnée ne fuite si la connexion VPN tombe.
2.  **Réseau Interne** : Les autres services communiquent entre eux via un réseau Docker dédié (`servarrnetwork`), ce qui leur permet de se trouver facilement et de manière sécurisée.

## Configuration Requise (`.env`)

Ce déploiement est entièrement configurable via un fichier `.env`. Créez ce fichier à la racine de ce dossier avant de lancer les services.

**Exemple de fichier `.env` :**
```env
# .env.example
# Ce fichier est un exemple. Créez un fichier .env et remplissez-le avec vos propres valeurs.

# --- Configuration Générale ---
TZ=Europe/Paris
PUID=1000
PGID=1000

# --- Chemins d'accès aux Médias (spécifiques à votre serveur hôte) ---
MEDIA_ROOT=/media
DOWNLOADS_DIR=/media/data

# --- Secrets VPN (exemple pour ProtonVPN) ---
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=VOTRE_CLÉ_PRIVÉE_WIREGUARD

# --- Configuration VPN ---
VPN_PORT_FORWARDING=on
PORT_FORWARD_ONLY=on
SERVER_COUNTRIES=France
SERVER_CITIES=Marseille
```

## Déploiement

Une fois le fichier `.env` configuré :

```bash
docker-compose up -d
```

## Notes Spécifiques

*   **Application Personnalisée** : Le service `gestionnaire-app` est construit localement à partir du Dockerfile situé dans le dossier `budget/`.
*   **Sauvegarde** : Tous les dossiers de configuration (`./sonarr`, `./radarr`, etc.) sont ignorés par Git. Ils contiennent l'état des applications et doivent faire l'objet d'une **sauvegarde régulière**.````
