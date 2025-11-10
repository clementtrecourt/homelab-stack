# Service Nginx Proxy Manager (Reverse Proxy)

Ce dossier contient la configuration pour déployer [Nginx Proxy Manager](https://nginxproxymanager.com/) via Docker Compose.

## Rôle

Ce service est le point d'entrée unique pour tout le trafic HTTP/S. Il agit comme un reverse proxy, gérant :
*   La terminaison des connexions SSL/TLS.
*   La génération et le renouvellement automatique des certificats Let's Encrypt.
*   Le routage des requêtes vers les services internes appropriés.

## Configuration Requise

Ce service ne nécessite aucune variable d'environnement dans un fichier `.env`. Toute la configuration se fait via l'interface web.

## Déploiement

```bash
docker-compose up -d
```

## Accès

*   **Interface d'administration** : `http://<IP_DU_LXC>:81`

## Sauvegarde (Important)

La configuration de ce service (hôtes, certificats) est stockée dans les volumes `data/` et `letsencrypt/`. Ces dossiers sont **ignorés par Git** et doivent faire l'objet d'une **sauvegarde régulière** pour pouvoir restaurer le service en cas de problème.
