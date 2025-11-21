# 🏰 Infrastructure Homelab de Niveau Entreprise

> **Infrastructure as Code (IaC) · Pipelines CI/CD · Observabilité Complète sur Proxmox**

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Traefik](https://img.shields.io/badge/Traefik-v3-24A1C1?style=for-the-badge&logo=traefik&logoColor=white)](https://traefik.io/)
[![Grafana](https://img.shields.io/badge/Grafana-10.0+-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

---

## 📖 Présentation

Ce projet démontre une **infrastructure de niveau production** fonctionnant dans un environnement homelab. Il réplique les standards et contraintes d'entreprise en utilisant des pratiques et outils DevOps modernes.

### 🎯 Principes Fondamentaux

**"Everything as Code"** — Zéro configuration manuelle des serveurs. Si un serveur tombe, il peut être automatiquement redéployé depuis le code.

| Pilier | Implémentation |
|--------|---------------|
| **Immutabilité** | Infrastructure définie de manière déclarative avec Terraform |
| **Automatisation** | Gestion de configuration via playbooks Ansible |
| **Livraison Continue** | Déploiements zéro-clic via pipelines Jenkins |
| **Observabilité** | Stack de monitoring complète (Logs + Métriques + Traces) |
| **Sécurité** | Isolation réseau, conteneurs non-privilégiés, gestion des secrets |

---

## 🏗️ Vue d'Ensemble de l'Architecture

L'infrastructure fonctionne sur **Proxmox VE** avec un nœud **Bastion** dédié orchestrant tous les déploiements. Aucun accès direct aux nœuds de production n'est nécessaire.

```mermaid
%%{init: {
  'theme': 'base', 
  'themeVariables': { 
    'primaryColor': '#3b4252', 
    'primaryTextColor': '#eceff4', 
    'primaryBorderColor': '#4c566a', 
    'lineColor': '#88c0d0', 
    'secondaryColor': '#2e3440', 
    'tertiaryColor': '#434c5e', 
    'fontFamily': 'Inter, system-ui, sans-serif'
  }
}}%%

graph TB
    Dev["<b>👨‍💻 Développeur</b><br/><i>Code source</i>"]
    GitHub["<b>📦 GitHub</b><br/><i>Dépôt Git</i>"]
    Jenkins["<b>⚙️ Jenkins</b><br/><i>Orchestrateur CI/CD</i>"]
    
    subgraph Proxmox["<b>🖥️ Hyperviseur Proxmox</b>"]
        direction TB
        
        Registry["<b>🐳 Registre Privé</b><br/><i>Images Docker</i>"]
        Bastion["<b>🛡️ Bastion</b><br/><i>IaC & Configuration</i>"]
        ProxmoxAPI(("<b>API Proxmox</b><br/><i>Provisioning</i>"))
        
        subgraph Production["<b>📦 Zone Production</b><br/><i>LXC Non-Privilégiés</i>"]
            direction LR
            Traefik["<b>🌐 Traefik</b><br/><i>Reverse Proxy</i><br/><i>SSL/TLS</i>"]
            Apps["<b>🚀 Applications</b><br/><i>Docker Compose</i><br/><i>Microservices</i>"]
            Security["<b>🔐 Sécurité</b><br/><i>AdGuard</i><br/><i>Authelia</i>"]
            Monitoring["<b>📊 Observabilité</b><br/><i>Prometheus</i><br/><i>Grafana</i><br/><i>Loki</i>"]
        end
    end

    Dev -->|"<b>git push</b>"| GitHub
    GitHub -->|"<b>webhook</b>"| Jenkins
    Jenkins -->|"<b>build & push</b>"| Registry
    Jenkins -->|"<b>Trigger</b>"| Bastion
    
    Bastion -->|"<b>Terraform</b><br/>provision infra"| ProxmoxAPI
    Bastion -->|"<b>Ansible</b><br/>config & deploy"| Production
    ProxmoxAPI -.->|"<b>Créer VMs/LXC</b>"| Production
    
    Registry -.->|"<b>pull images</b>"| Apps
    
    Traefik -->|"<b>Routing</b>"| Apps
    Traefik -->|"<b>Auth</b>"| Security
    
    Apps -.->|"<b>Métriques</b>"| Monitoring
    Traefik -.->|"<b>Logs</b>"| Monitoring
    Security -.->|"<b>Alertes</b>"| Monitoring

    classDef devStyle fill:#5e81ac,stroke:#81a1c1,stroke-width:2px,color:#eceff4
    classDef githubStyle fill:#2e3440,stroke:#4c566a,stroke-width:2px,color:#eceff4
    classDef jenkinsStyle fill:#bf616a,stroke:#d08770,stroke-width:2px,color:#eceff4
    classDef bastionStyle fill:#5e81ac,stroke:#88c0d0,stroke-width:2px,color:#eceff4
    classDef registryStyle fill:#81a1c1,stroke:#8fbcbb,stroke-width:2px,color:#eceff4
    classDef apiStyle fill:#ebcb8b,stroke:#d08770,stroke-width:2px,color:#2e3440
    classDef proxmoxStyle fill:#3b4252,stroke:#4c566a,stroke-width:2px,color:#eceff4
    classDef prodStyle fill:#434c5e,stroke:#4c566a,stroke-width:2px,color:#eceff4
    classDef traefikStyle fill:#8fbcbb,stroke:#88c0d0,stroke-width:2px,color:#2e3440
    classDef appsStyle fill:#a3be8c,stroke:#8fbcbb,stroke-width:2px,color:#2e3440
    classDef securityStyle fill:#d08770,stroke:#bf616a,stroke-width:2px,color:#eceff4
    classDef monitoringStyle fill:#b48ead,stroke:#bf616a,stroke-width:2px,color:#eceff4

    class Dev devStyle
    class GitHub githubStyle
    class Jenkins jenkinsStyle
    class Bastion bastionStyle
    class Registry registryStyle
    class ProxmoxAPI apiStyle
    class Proxmox proxmoxStyle
    class Production prodStyle
    class Traefik traefikStyle
    class Apps appsStyle
    class Security securityStyle
    class Monitoring monitoringStyle
```

---

## 🛠️ Stack Technologique

### Couche Infrastructure

| Composant | Technologie | Objectif |
|-----------|-----------|---------|
| **Provisioning** | Terraform | Gestion du cycle de vie des conteneurs LXC (état stocké sur Bastion) |
| **Configuration** | Ansible | Hardening OS, installation Docker, gestion utilisateurs, rotation logs |
| **Hyperviseur** | Proxmox VE | Hyperviseur Type-1 pour orchestration LXC et VM |

### Couche Application

| Composant | Technologie | Objectif |
|-----------|-----------|---------|
| **CI/CD** | Jenkins | Pipelines déclaratives (DSL Groovy) pour infra et apps |
| **Orchestration** | Docker Compose | Gestion d'applications multi-conteneurs |
| **Réseau** | Traefik v3 | Reverse proxy dynamique avec SSL/TLS automatique |
| **Registre** | Docker Registry | Stockage privé d'images avec authentification |

### Sécurité & Monitoring

| Composant | Technologie | Objectif |
|-----------|-----------|---------|
| **VPN** | Tailscale | Réseau mesh sécurisé pour l'administration |
| **Secrets** | Ansible Vault | Gestion chiffrée des identifiants |
| **Métriques** | Prometheus + Node Exporter | Collecte de métriques time-series |
| **Visualisation** | Grafana | Dashboards unifiés pour la santé de l'infrastructure |
| **Logs** | Loki (prévu) | Agrégation centralisée des logs |

---

## 🚀 Architecture des Pipelines CI/CD

Le projet implémente des **pipelines séparés** pour les cycles de vie infrastructure et applications.

### 🔵 Pipeline Application (Intégration Continue)

Déclenché lors de modifications du code applicatif (ex: Budget App).

```
┌─────────────┐     ┌──────────┐     ┌─────────┐     ┌──────────────┐
│  Git Push   │ ──> │  Build   │ ──> │  Tests  │ ──> │ Push vers    │
│             │     │  Docker  │     │  Units  │     │ Registre     │
└─────────────┘     └──────────┘     └─────────┘     └──────────────┘
```

**Étapes :**
1. **Build** — Création d'image Docker multi-stage
2. **Test** — Tests unitaires + validation linting
3. **Push** — Tag et publication de l'image vers le registre privé

### 🟢 Pipeline Infrastructure (Déploiement Continu)

Déclenché lors de modifications Terraform/Ansible.

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌──────────┐
│ Changements │ ──> │ Terraform    │ ──> │ Configuration  │ ──> │ Restart  │
│ Terraform   │     │ Plan/Apply   │     │ Ansible        │     │ Services │
└─────────────┘     └──────────────┘     └────────────────┘     └──────────┘
```

**Étapes :**
1. **Checkout** — Récupération du code infrastructure sur Bastion
2. **Plan/Apply** — Mise à jour ressources compute et topologie réseau
3. **Configure** — Exécution playbooks Ansible pour déploiement services
4. **Validate** — Health checks et tests de fumée

---

## 📊 Stack d'Observabilité

### Architecture Monitoring

```
┌──────────────────────────────────────────────────────┐
│               Dashboards Grafana                     │
│           (Visualisation Unifiée)                    │
└─────────────────┬────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│  Prometheus   │   │   InfluxDB    │
│  (Métriques)  │   │ (Time-series) │
└───────┬───────┘   └───────┬───────┘
        │                   │
        └─────────┬─────────┘
                  ▼
        ┌──────────────────┐
        │  Node Exporter   │
        │    Telegraf      │
        │ (Collecte Data)  │
        └──────────────────┘
```

### Métriques Clés Surveillées

- 📈 **Système** : CPU, RAM, I/O disque, débit réseau
- 🐳 **Conteneurs** : Utilisation ressources Docker, compteurs de restart
- 🌐 **Réseau** : Taux de requêtes Traefik, temps de réponse, taux d'erreur
- 💾 **Stockage** : Utilisation disque LXC, pools de stockage Proxmox

> **Note** : Ajoutez ici vos captures d'écran de dashboards Grafana pour présenter les données de monitoring réelles.

---

## 🔐 Implémentation Sécurité

La sécurité est intégrée dès la phase de conception (**Security by Design**).

### Stratégie de Défense en Profondeur

| Couche | Implémentation |
|-------|---------------|
| **Moindre Privilège** | Tous les conteneurs LXC fonctionnent en mode non-privilégié (pas de root sur l'hôte) |
| **Gestion Secrets** | Zéro identifiant en clair — chiffrement Ansible Vault |
| **Segmentation Réseau** | Zone production isolée du réseau de management |
| **Surface d'Attaque** | Seul le port 443 (HTTPS) exposé via Traefik |
| **Hardening SSH** | Authentification par clés uniquement, accès Bastion seul |
| **Accès Admin** | VPN mesh Tailscale — pas de port SSH 22 public |
| **Gestion Certificats** | Let's Encrypt automatisé via Traefik |

---

## 📦 Inventaire Infrastructure

| ID | Hostname | IP | vCPU | RAM | Rôle |
|----|----------|-------|------|-----|------|
| 99 | `bastion-admin` | 192.168.1.20 | 2 | 4GB | Control Plane · Terraform · Ansible |
| 200 | `traefik` | 192.168.1.30 | 2 | 2GB | Reverse Proxy · Terminaison SSL |
| 201 | `servarr` | 192.168.1.31 | 4 | 8GB | Serveur Applications · Docker Compose |
| 203 | `jenkins` | 192.168.1.33 | 2 | 4GB | Contrôleur CI/CD · Registre Docker |
| 204 | `monitoring` | 192.168.1.34 | 2 | 4GB | Prometheus · Grafana · Alerting |

---

## 🚀 Guide de Démarrage Rapide

### Prérequis

- Proxmox VE 8.0+ installé sur bare metal
- Git et clé SSH configurés
- Ansible 2.15+ sur votre machine locale

### Étape 1 : Bootstrap du Nœud Bastion

Depuis votre **poste de travail local** :

```bash
git clone https://github.com/votre-username/homelab-infrastructure.git
cd homelab-infrastructure/terraform/bastion

terraform init
terraform apply -auto-approve
```

### Étape 2 : Configuration Initiale

Connexion au Bastion et exécution du setup initial :

```bash
ansible-playbook -i inventory/bastion.yml playbooks/setup_bastion.yml --ask-vault-pass
```

### Étape 3 : Déploiement de l'Infrastructure Complète

Exécution du script de déploiement maître :

```bash
ssh root@bastion.votredomaine.com
cd /opt/homelab
./scripts/deploy_infrastructure.sh
```

### Étape 4 : Vérification du Déploiement

Vérification de la santé des services :

```bash
ansible all -i inventory/production.yml -m ping
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Accès au dashboard Grafana : `https://monitoring.votredomaine.com`

---

## 📁 Structure du Dépôt

```
homelab-infrastructure/
├── ansible/
│   ├── playbooks/          # Scripts d'automatisation Ansible
│   ├── roles/              # Rôles Ansible réutilisables
│   └── inventory/          # Définitions des hôtes
├── terraform/
│   ├── bastion/            # Provisioning du nœud Bastion
│   ├── modules/            # Modules Terraform réutilisables
│   └── production/         # Définitions LXC production
├── jenkins/
│   ├── pipelines/          # Jenkinsfiles (Déclaratifs)
│   └── jobs/               # Configurations des jobs
├── docker/
│   ├── compose/            # Stacks Docker Compose
│   └── images/             # Dockerfiles personnalisés
├── monitoring/
│   ├── grafana/            # Définitions dashboards (JSON)
│   └── prometheus/         # Configurations scraping
└── docs/
    ├── architecture/       # Diagrammes d'architecture
    └── runbooks/           # Procédures opérationnelles
```

---

## 🎯 Roadmap

- [ ] **GitOps** : Migration vers ArgoCD pour livraison applicative déclarative
- [ ] **Service Mesh** : Évaluation Istio/Linkerd pour gestion trafic avancée
- [ ] **Stratégie Backup** : Intégration automatisée Proxmox Backup Server
- [ ] **Haute Disponibilité** : Ajout clustering Proxmox (setup 3 nœuds)
- [ ] **Observabilité** : Intégration Loki pour centralisation logs
- [ ] **Sécurité** : Implémentation Vault pour génération dynamique secrets

---

## 📚 Ressources & Documentation

- [Documentation Proxmox VE](https://pve.proxmox.com/pve-docs/)
- [Provider Terraform Proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Bonnes Pratiques Ansible](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Syntaxe Pipeline Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

## 👤 Auteur

**Clément Trecourt**  
Ingénieur DevOps | Passionné d'Automatisation

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Se_Connecter-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/votre-profil)
[![GitHub](https://img.shields.io/badge/GitHub-Suivre-181717?style=flat&logo=github&logoColor=white)](https://github.com/votre-username)
[![Email](https://img.shields.io/badge/Email-Contact-D14836?style=flat&logo=gmail&logoColor=white)](mailto:votre.email@exemple.com)

---

## 📄 Licence

Ce projet est sous licence MIT — voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🙏 Remerciements

Construit avec passion pour l'automatisation et l'excellence infrastructurelle.

> *"L'automatisation n'est pas une fin en soi — c'est le moyen de dormir tranquille."*

---

<div align="center">
⭐ Mettez une étoile à ce dépôt si vous le trouvez utile ! ⭐
</div>