# Homelab Kubernetes GitOps Monorepo

A single-node **Kubernetes (`k3s`) + GitOps (`Argo CD`)** homelab managed declaratively from this repository, featuring:

- **Cluster**: Single-node [k3s](https://k3s.io/) on Ubuntu Linux with built-in `local-path` persistent storage
- **GitOps**: [Argo CD](https://argo-cd.readthedocs.io/) using the **App-of-Apps** pattern with Sync Waves
- **Secrets Management**: [External Secrets Operator (ESO)](https://external-secrets.io/) synced from **AWS Systems Manager (SSM) Parameter Store** (Standard `SecureString` — $0/mo, zero plaintext secrets in Git)
- **Networking & HTTPS**: [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator) — fully containerized Tailscale proxies giving every app a private `https://<app>.<tailnet>.ts.net` URL with automatic TLS and zero open router ports
- **CI Validation**: GitHub Actions validating Kustomize builds and Kubernetes schemas on every push/PR

> New to Kubernetes? Start with [docs/kubernetes-101.md](docs/kubernetes-101.md) for a plain-English guide mapping Docker Compose concepts to this repo.

---

## Architecture

```
GitHub (this repo)
   │
   ▼  watches & auto-syncs
Argo CD (root-app / App-of-Apps)
   ├── Wave 0: External Secrets Operator (Helm)
   ├── Wave 1: ClusterSecretStore ──────────────► AWS SSM Parameter Store (/homelab/*)
   ├── Wave 2: Tailscale Kubernetes Operator ───► Tailnet (*.ts.net HTTPS proxies)
   └── Wave 3: Workloads
                 ├── Argo CD UI Ingress (https://argocd.<tailnet>.ts.net)
                 └── Beszel Hub         (https://beszel.<tailnet>.ts.net)
```

---

## Repository Layout

```text
.
├── bootstrap/
│   ├── argocd/                 # Initial Argo CD install + root App-of-Apps manifest
│   └── scripts/bootstrap.sh    # Guided one-time cluster bootstrap script
├── infrastructure/
│   ├── applications/           # Argo CD Applications for core cluster services
│   ├── argocd-ingress/         # Tailscale Ingress for the Argo CD web UI
│   ├── external-secrets-config/# ClusterSecretStore connecting ESO -> AWS SSM
│   └── tailscale-operator/     # ExternalSecret pulling Tailscale OAuth creds from AWS SSM
├── apps/
│   ├── applications/           # Argo CD Applications for user-facing workloads
│   └── beszel/                 # Pilot workload: Beszel monitoring hub
├── docs/
│   ├── kubernetes-101.md       # Beginner guide to Kubernetes & GitOps in this repo
│   └── aws-ssm-setup.md        # Step-by-step AWS IAM + SSM Parameter Store setup
└── .github/workflows/
    └── validate.yaml           # CI: Kustomize build + Kubernetes manifest validation
```

---

## Quick Start (Bootstrap Order)

1. **Set up AWS SSM Parameter Store & IAM credentials** — follow [docs/aws-ssm-setup.md](docs/aws-ssm-setup.md).
2. **Create Tailscale OAuth credentials** (in the Tailscale admin console with `devices:core` + `auth_keys` write scopes and tag `tag:k8s-operator`) and store them in AWS SSM Parameter Store:
   - `/homelab/tailscale/oauth-client-id`
   - `/homelab/tailscale/oauth-client-secret`
3. **Install k3s and bootstrap Argo CD** — review and run [bootstrap/scripts/bootstrap.sh](bootstrap/scripts/bootstrap.sh).
4. **Access Argo CD** at `https://argocd.<your-tailnet>.ts.net` and watch it sync the entire cluster from Git!

---

## Migration Roadmap

- [x] Core platform architecture (`k3s` + `Argo CD` + `ESO` + `AWS SSM` + `Tailscale Operator`)
- [x] Pilot app: **Beszel Hub** (`apps/beszel`)
- [ ] **Jellyfin** + Intel iGPU (`/dev/dri/renderD128`) device plugin + S3 Glacier backup `CronJob`
- [ ] **Immich** (Server + OpenVINO ML + VectorChord Postgres + Valkey) + S3 Glacier backup `CronJob`
- [ ] **Nextcloud** (App + Cron + Postgres + Redis)
- [ ] Automated dependency PRs via **Renovate**
