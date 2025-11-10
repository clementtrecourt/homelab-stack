# Mon Infrastructure Homelab as Code

Ce dépôt contient l'intégralité de la configuration de mon infrastructure personnelle (Homelab). Le but de ce projet est de gérer 100% de l'infrastructure en suivant les principes de l'**Infrastructure as Code (IaC)**.

La philosophie est simple : aucune configuration manuelle n'est autorisée sur les serveurs. Toute modification doit être effectuée via ce dépôt Git, garantissant une infrastructure **reproductible**, **documentée** et **sécurisée**.

## Architecture Générale

L'infrastructure repose sur un hyperviseur Proxmox qui héberge plusieurs conteneurs LXC, chacun avec un rôle défini :

*   **LXC 100 (`lxc-100-adguard`)** : Serveur DNS. Gère le filtrage des publicités et les résolutions DNS locales pour l'ensemble du réseau.
*   **LXC 101 (`lxc-101-nginx-proxy-manager`)** : Reverse Proxy. C'est le point d'entrée unique pour tous les services HTTP/S. Il gère la terminaison SSL et le routage des requêtes vers les bons services.
*   **LXC 103 (`lxc-103-servarr-stack`)** : Cœur applicatif. Héberge la stack de services média (*arrs, Jellyfin) ainsi que des applications personnalisées. Une partie de ses services est routée à travers un tunnel VPN pour la confidentialité.

## Structure du Dépôt

Chaque dossier à la racine de ce dépôt correspond à un LXC et contient la définition de ses services via `docker-compose`.

*   `lxc-100-adguard/` : Définition du service AdGuard Home.
*   `lxc-101-nginx-proxy-manager/` : Définition du service Nginx Proxy Manager.
*   `lxc-103-servarr-stack/` : Définition de la stack média complète, incluant le client VPN et une application custom.

## Déploiement

Chaque service est autonome. Pour déployer un LXC :

1.  Se connecter en SSH au LXC cible.
2.  Cloner ce dépôt : `git clone <URL_DU_DÉPÔT> .`
3.  Naviguer dans le dossier correspondant (ex: `cd lxc-100-adguard`).
4.  Créer un fichier `.env` en se basant sur les instructions du `README.md` du sous-dossier. **Ce fichier contient les secrets et n'est pas versionné dans Git.**
5.  Lancer les services : `docker-compose up -d`.

## Principes Clés Mis en Œuvre

*   **Infrastructure as Code** : Tout est décrit dans des fichiers YAML et géré par Git.
*   **Gestion des Secrets** : Séparation stricte de la configuration (commitée) et des secrets (via des fichiers `.env` ignorés).
*   **Isolation** : Chaque service tourne dans son propre conteneur Docker, et chaque groupe de services est isolé dans son LXC.
*   **Reproductibilité** : Capacité de reconstruire n'importe quel service ou l'infrastructure entière à partir de ce dépôt et d'une sauvegarde des données.

## Prochaines Étapes

- [ ] **Automatisation du déploiement** avec Ansible pour provisionner les LXC de manière 100% automatique.
- [ ] **Migration vers Kubernetes (k3s)** pour une orchestration avancée.
- [ ] **Mise en place de GitOps** avec ArgoCD pour des déploiements continus basés sur les commits Git.
