<div align="center">

# K3s Homelab — GitOps Platform

**Infrastructure Kubernetes entièrement automatisée, déployée en production sur un homelab à ressources contraintes.**

[![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=flat-square&logo=terraform&logoColor=white)](https://terraform.io)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white)](https://ansible.com)
[![K3s](https://img.shields.io/badge/K3s-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](https://k3s.io)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat-square&logo=argo&logoColor=white)](https://argoproj.github.io/argo-cd/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare_Zero_Trust-F38020?style=flat-square&logo=cloudflare&logoColor=white)](https://cloudflare.com)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

</div>

---

## À propos

Ce dépôt est une plateforme GitOps de niveau production déployée sur un homelab : Terraform provisionne les VMs, Ansible configure les nœuds, K3s orchestre les workloads, ArgoCD réconcilie en continu depuis Git. Aucun port entrant, aucun secret en clair, déploiement de zéro à production en ~20 minutes.

L'objectif n'est pas de simuler du DevOps — c'est de le pratiquer sur une infrastructure réelle, avec des contraintes réelles.

---

## Architecture

```
Internet ──► Cloudflare Edge ──► Cloudflare Tunnel (sortant) ──► Traefik v3
                                                                        │
                     ┌──────────────────────────────────────────────────┤
                     │                                                  │
              ┌──────▼──────┐                                   ┌───────▼──────┐
              │   ArgoCD    │ ◄── Git (feat/k3s-migration)       │  Applications │
              │ GitOps Core │ ◄── Git (feat/monitoring)          │  Uptime Kuma  │
              └──────┬──────┘                                   │  Jellyfin     │
                     │                                           └───────────────┘
          ┌──────────┴──────────┐
          │                     │
   ┌──────▼──────┐      ┌───────▼──────┐
   │  Worker 1   │      │   Worker 2   │
   │  NFS mount  │      │  NFS mount   │
   │  /mnt/data  │      │  /mnt/data   │
   └─────────────┘      └─────────────┘
          │                     │
          └──────────┬──────────┘
                     │
              ┌──────▼──────────────────────┐
              │  NFS Server 192.168.1.120    │
              │  /data — config + médias     │
              └─────────────────────────────┘

Cluster : 1 Master (control plane dédié) + 2 Workers
```

**Flux réseau :** utilisateur → Cloudflare Edge → tunnel chiffré sortant (zéro port ouvert en entrée) → Traefik route vers les services → TLS wildcard via Cert-Manager + Let's Encrypt DNS-01.


---

## 🟢 Live Status Page

La disponibilité de cette infrastructure est supervisée en temps réel depuis l'extérieur du cluster et accessible publiquement sans authentification :

👉 **[https://status.clem-ops.org](https://status.clem-ops.org)**

[![Uptime Kuma](https://img.shields.io/badge/Uptime_Kuma-🟢_Live_Status-3db230?style=for-the-badge&logo=statuspage&logoColor=white)](https://status.clem-ops.org)

*(Cette page de statut est hébergée au sein du cluster K3s, routée directement par Cloudflare Tunnel, et configurée pour contourner de manière ciblée la politique d'accès Zero Trust globale via une règle d'exclusion d'identité).*

<p align="center">
  <img src="docs/status-page-screenshot.png" width="850" alt="Uptime Kuma Live Status Page">
</p>

---

## Stack

| Couche | Technologie | Rôle |
|---|---|---|
| IaC | Terraform + Proxmox Provider | Provisionnement VMs, inventaire Ansible dynamique |
| Configuration | Ansible (roles) | Hardening OS, K3s, montage NFS, sysctl |
| Orchestration | K3s | Kubernetes léger, 1 Master + 2 Workers |
| GitOps | ArgoCD + ApplicationSet | Réconciliation continue, auto-découverte apps |
| Ingress | Traefik v3 | IngressController, terminaison TLS |
| Réseau | Cloudflare Tunnel + Zero Trust | Exposition sans port entrant |
| Secrets | Sealed Secrets (Bitnami) | Chiffrement asymétrique, git-compatible |
| Certificats | Cert-Manager | Wildcard Let's Encrypt via DNS-01 Cloudflare |
| Monitoring | kube-prometheus-stack | Prometheus Operator, Alertmanager, Grafana |
| Logs | Loki + Promtail | Centralisation logs, dashboard Grafana custom |
| Stockage | NFS + PersistentVolumes | Volumes Jellyfin (config NFS PV + médias hostPath) |
| Applications | Uptime Kuma, Jellyfin | Monitoring disponibilité, streaming média |

---

## Structure du dépôt

```
.
├── infrastructure/
│   ├── terraform/              # Provisionnement VMs Proxmox
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf          # Génère inventory.tf.ini pour Ansible
│   └── ansible/
│       ├── playbooks/
│       └── roles/
│           ├── k3s_master/     # Install + config K3s master
│           ├── k3s_worker/     # Install K3s workers + join
│           └── nfs_client/     # Monte 192.168.1.120:/data → /mnt/data
│
└── kubernetes/
    ├── root-app.yaml           # App-of-apps ArgoCD (branche: feat/k3s-migration)
    ├── system/
    │   ├── prometheus-stack.yaml   # kube-prometheus-stack (Helm)
    │   ├── loki-app.yaml
    │   ├── promtail-app.yaml
    │   └── loki-dashboard.yaml     # Dashboard Grafana custom
    └── apps/                   # Découverte via ApplicationSet (branche: feat/monitoring)
        ├── uptime-kuma/
        └── jellyfin/
            └── jellyfin.yaml   # PV NFS config + hostPath médias
```

---

## Pipeline de déploiement

```bash
git clone https://github.com/clementtrecourt/k3s-homelab.git
cd k3s-homelab/infrastructure
./deploy.sh
```

**1 — Terraform** provisionne les VMs Debian sur Proxmox et génère l'inventaire Ansible dynamiquement via `outputs.tf`.

**2 — Ansible** applique le hardening OS (sysctl, UFW, SSH par clé uniquement), désactive le swap, monte le partage NFS sur les workers, installe K3s et joint les workers au master.

**3 — Kubernetes** bootstrap les services core (Sealed Secrets, Cert-Manager, Cloudflare Tunnel), puis ArgoCD prend le relais : `root-app.yaml` (branche `feat/k3s-migration`) pour les composants système, ApplicationSet (branche `feat/monitoring`) pour la découverte automatique de `kubernetes/apps/*`.

```
~5 min   Terraform — provisionnement VMs
~3 min   Ansible  — hardening + K3s + NFS
~2 min   K3s      — cluster up, kubeconfig prêt
~5 min   ArgoCD   — bootstrap + services core
~5 min   Apps     — réconciliation GitOps
─────────────────────────────────────────
~20 min  de zéro à production
```

---

## Sécurité

**Réseau :** aucun port exposé. Le tunnel Cloudflare établit une connexion sortante depuis le cluster — le flux entrant n'existe pas au niveau firewall.

**Secrets :** Sealed Secrets chiffre asymétriquement avec la clé publique du cluster. Les `SealedSecret` sont versionnés dans Git — seul le controller interne peut déchiffrer.

```bash
kubeseal --cert pub-sealed-secrets.pem \
  --format yaml < secret.yaml > sealed-secret.yaml

git add kubernetes/apps/*/sealed-secret.yaml  # safe to commit
```

**OS :** authentification SSH par clé uniquement, UFW restrictif, tuning sysctl, mises à jour automatiques.

**Certificats :** Cert-Manager émet et renouvelle le wildcard `*.domaine.com` via challenge DNS-01 Cloudflare — aucune intervention manuelle.

---

## Monitoring & Observabilité

Stack PLG déployée via ArgoCD :

- **kube-prometheus-stack** — Prometheus Operator, scraping métriques cluster, Alertmanager
- **Loki + Promtail** — collecte et centralisation des logs applicatifs
- **Grafana** — dashboards métriques + dashboard Loki custom (`loki-dashboard.yaml`)
- **ArgoCD UI** — état de sync et santé de chaque Application en temps réel

Roadmap : Alertmanager → Discord/Slack, tracing distribué (Tempo).

---

## GitOps — Pattern ApplicationSet

Tout dossier dans `kubernetes/apps/` déclenche automatiquement le déploiement d'une Application ArgoCD :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps
spec:
  generators:
    - git:
        repoURL: https://github.com/clementtrecourt/k3s-homelab
        revision: feat/monitoring
        directories:
          - path: kubernetes/apps/*
  template:
    spec:
      source:
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
```

> **Branches actives :** `root-app.yaml` → `feat/k3s-migration` (système), ApplicationSet → `feat/monitoring` (apps). Ces deux branches doivent être synchronisées sur le remote pour éviter les erreurs de réconciliation ArgoCD.

---

## Accès post-déploiement

```bash
# Console ArgoCD (via Cloudflare Tunnel)
open https://argocd.clem-ops.org

# Mot de passe admin initial
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Break-glass si tunnel hors-ligne
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Suivre la réconciliation
watch kubectl get pods -A
```

---

## Prérequis

- Hyperviseur Proxmox accessible en SSH
- Compte Cloudflare avec token API (permissions DNS:Edit)
- Clé publique Sealed Secrets (`pub-sealed-secrets.pem`)
- Partage NFS disponible sur `192.168.1.120:/data`

---

## Compétences démontrées

`Terraform` `Ansible` `Kubernetes / K3s` `ArgoCD` `GitOps` `Helm` `Traefik` `Cloudflare Zero Trust` `Sealed Secrets` `Cert-Manager` `Prometheus` `Loki` `Grafana` `NFS` `Linux hardening` `IaC` `Configuration Management` `Observabilité`

---

<div align="center">

**Clément Trecourt**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/clement-trecourt/)
[![Email](https://img.shields.io/badge/ProtonMail-8B89CC?style=flat-square&logo=protonmail&logoColor=white)](mailto:clementt.pro@protonmail.com)

</div>
