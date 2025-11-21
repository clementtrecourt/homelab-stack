    
# 🏰 Homelab Infrastructure as Code (IaC)

<div align="center">

![Status](https://img.shields.io/badge/Status-Production-2ea44f?style=for-the-badge&logo=check)
![Terraform](https://img.shields.io/badge/Terraform-v1.9-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-v2.16-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)

</div>

---

## 📖 À propos

Ce projet contient l'intégralité du code source permettant de déployer, configurer et maintenir mon infrastructure personnelle (Homelab). Il a été conçu avec une philosophie **"Everything as Code"** stricte : aucune intervention manuelle n'est effectuée sur les serveurs de production.

L'objectif est de simuler un environnement d'entreprise réel avec des pratiques **DevOps** modernes : Iac, GitOps, CI/CD, Monitoring et Sécurité.

---

## 📐 Architecture

L'infrastructure repose sur un hyperviseur **Proxmox VE**. Une machine "Bastion" (Management Node) orchestre le déploiement des autres services via Terraform et Ansible, déclenchée automatiquement par Jenkins.

graph TD
    User[💻 Développeur] -->|Git Push| GitHub[GitHub Repo]
    GitHub -->|Polling (H/5)| Jenkins[⚙️ LXC Jenkins]
    
    subgraph "Proxmox Host"
        Jenkins -->|Build & Push Image| Registry[📦 Docker Registry]
        Jenkins -->|Trigger Deployment (SSH)| Bastion[🛡️ LXC Bastion]
        
        Bastion -->|Provisioning (Terraform)| PVE((Proxmox API))
        Bastion -->|Configuration (Ansible)| LXCs
        
        PVE -.->|Création/Destruction| LXCs
        
        subgraph "LXC Containers (Production)"
            Traefik[🌐 Traefik (Reverse Proxy)]
            Servarr[🎬 Media Stack + Apps]
            AdGuard[🛡️ AdGuard (DNS)]
            Monitoring[📊 Grafana/Prometheus]
        end
    end

  

🛠️ Stack Technique
Domaine	Technologie	Usage
Provisioning	Terraform	Création et cycle de vie des conteneurs LXC sur Proxmox.
Config Mgmt	Ansible	Installation des paquets, sécurisation, déploiement Docker.
CI/CD	Jenkins	Pipelines déclaratifs pour le build d'images et le déploiement infra.
Conteneurisation	Docker Compose	Orchestration des micro-services applicatifs.
Réseau	Traefik	Reverse Proxy avec découverte dynamique des services.
Accès	Tailscale	Mesh VPN pour l'administration sécurisée sans ouverture de port.
Monitoring	TIG Stack	Node Exporter, Prometheus, Grafana pour l'observabilité.
🚀 Flux de Déploiement (CI/CD)

Ce projet implémente un pipeline complet d'intégration et de déploiement continu :

    CI (Intégration Continue) :

        Modification du code de l'application interne "Budget" (Node.js).

        Jenkins détecte le changement, clone le repo et construit l'image Docker.

        L'image est versionnée et poussée vers le Registre Docker Privé hébergé localement.

    CD (Déploiement Continu) :

        Jenkins se connecte via SSH au Bastion d'Administration.

        Le Bastion récupère la dernière version du code Infra (Git Pull).

        Terraform met à jour l'infrastructure (State local).

        Ansible configure les serveurs et force le redéploiement des conteneurs avec la nouvelle image.

📦 Cartographie des Services

L'infrastructure est segmentée en conteneurs LXC "Unprivileged" pour une sécurité et une isolation maximales.
LXC ID	Hostname	IP	Rôle Principal
99	bastion-admin	192.168.1.20	Cerveau de l'infra. Détient les clés SSH, le State Terraform et les secrets. Seul point d'entrée SSH autorisé.
200	traefik	192.168.1.30	Point d'entrée HTTP/S. Gère le routage, le SSL et le Load Balancing vers les autres LXC.
201	servarr	192.168.1.31	Applications. Héberge la stack média (*arr, Jellyfin, qBittorrent) et les apps métiers (Budget).
202	adguard	192.168.1.32	DNS. Filtrage réseau (Pubs/Trackers) et résolution DNS locale (*.homelab.local).
203	jenkins	192.168.1.33	Usine Logicielle. Serveur Jenkins et Docker Registry (Port 5000).
204	monitoring	192.168.1.34	Observabilité. Prometheus (Time Series DB), Node Exporter et Grafana.
🔐 Sécurité & Bonnes Pratiques

    Gestion des Secrets : Les variables sensibles (Mots de passe, Clés API, Hashs) ne sont jamais committées en clair. Elles sont gérées via Ansible Vault ou injectées dynamiquement via le Bastion.

    Moindre Privilège : Tous les conteneurs LXC sont configurés en mode "Unprivileged" pour isoler le root du conteneur du root de l'hôte.

    Isolation Réseau : Utilisation de réseaux Docker internes. Seul Traefik expose les ports 80/443.

    Zéro Port Ouvert : L'accès à l'administration depuis l'extérieur se fait exclusivement via un tunnel Tailscale.

🏁 Démarrage (Bootstrap)

Pour déployer cette infrastructure sur un serveur Proxmox vierge :

    Pré-requis : Un serveur Proxmox VE accessible avec un stockage local-lvm.

    Initialisation du Bastion :
    Depuis un poste de travail local :
    code Bash

    
cd terraform-bastion
terraform init && terraform apply

  

Configuration du Bastion :
code Bash

    
ansible-playbook -i inventory.bastion provisioning/setup_bastion.yml

  

Déploiement Global :
Connectez-vous au Bastion et lancez le script maître :
code Bash

        
    ssh root@192.168.1.20
    ./deploy_infra.sh

      

👤 Auteur

Clément Trecourt
Junior DevOps Engineer & Homelab Enthusiast

    "L'automatisation n'est pas une fin en soi, c'est un moyen de dormir tranquille."