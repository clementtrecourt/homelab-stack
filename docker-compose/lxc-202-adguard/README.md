# Service AdGuard Home

Ce dossier contient la configuration pour déployer le service de filtrage DNS [AdGuard Home](https://adguard.com/fr/adguard-home/overview.html) via Docker Compose.

## Rôle

AdGuard Home fournit un service de filtrage DNS pour tout le réseau domestique, bloquant les publicités et les traqueurs. Il sert également de serveur DNS local.

## Configuration Requise

Ce service gère son mot de passe de manière sécurisée en utilisant un template et une variable d'environnement.

1.  Créez un fichier `.env` à la racine de ce dossier.
2.  Ajoutez-y la variable suivante avec le hash de votre mot de passe (généré par AdGuard ou via `htpasswd`) :

    ```env
    # .env
    ADGUARD_PASSWORD_HASH='votre_hash_ici'
    ```

Le fichier `docker-compose.yml` utilise ensuite ce template pour générer le fichier de configuration final au démarrage du conteneur.

## Déploiement

```bash
docker-compose up -d
```

## Accès

*   **Interface Web** : `http://<IP_DU_LXC>:PORT` (selon les ports que vous avez mappés pour l'UI).
*   **Serveur DNS** : `<IP_DU_LXC>` sur le port `53`.
