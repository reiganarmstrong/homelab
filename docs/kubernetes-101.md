# Kubernetes & GitOps 101 (For This Homelab)

If you're coming from **Docker Compose** and **systemd**, here is how every piece of this repository maps to what you already know.

---

## Docker Compose → Kubernetes Cheat Sheet

| Docker Compose / Linux | Kubernetes Equivalent | What it does |
| :--- | :--- | :--- |
| `docker-compose.yml` service | `Deployment` (or `StatefulSet`) | Declares which container image to run, env vars, health checks, and how many copies (`replicas`). |
| `ports:` + reverse proxy | `Service` + `Ingress` | `Service` gives pods a stable internal IP/DNS name. `Ingress` exposes HTTP/HTTPS externally (here, via Tailscale). |
| `volumes:` | `PersistentVolumeClaim` (PVC) | Requests persistent storage on disk so data survives container restarts/upgrades. |
| `.env` (non-secret config) | `ConfigMap` | Key-value configuration mounted or injected as environment variables. |
| `.env` (passwords / tokens) | `Secret` (managed by `ExternalSecret`) | Sensitive values synced automatically from AWS SSM Parameter Store by External Secrets Operator. |
| `systemd` timer + service | `CronJob` | Runs a container on a cron schedule (perfect for S3 Glacier backups). |
| Host daemon on every server | `DaemonSet` | Ensures one copy of a pod runs on every node in the cluster (e.g., node monitoring agents). |
| Separate compose projects | `Namespace` | Logical folder/isolation boundary inside the cluster (e.g., `argocd`, `beszel`, `tailscale`). |

---

## How GitOps Works (Argo CD)

Instead of SSHing into your server and running `docker compose up -d`:

1. You edit a YAML file in this Git repo and push to `main`.
2. **Argo CD** (running inside your cluster) detects the new commit.
3. Argo CD compares what's in Git (**desired state**) against what's running in k3s (**live state**).
4. Argo CD automatically applies the difference — and if someone manually edits a resource in the cluster, `selfHeal: true` reverts it back to match Git.

### The "App-of-Apps" Pattern

You only manually apply **one** file during bootstrap: [`bootstrap/argocd/root-app.yaml`](../bootstrap/argocd/root-app.yaml).

That single root `Application` watches:
- `infrastructure/applications/` (cluster-wide plumbing: ESO, AWS SSM config, Tailscale Operator)
- `apps/applications/` (your services: Beszel, and later Jellyfin, Immich, Nextcloud)

**Sync Waves** (`argocd.argoproj.io/sync-wave`) tell Argo CD what order to deploy things in:
- **Wave 0**: External Secrets Operator (installs the secret-syncing controller)
- **Wave 1**: `ClusterSecretStore` (connects ESO to AWS SSM Parameter Store)
- **Wave 2**: Tailscale Operator (pulls its OAuth credentials via ESO, then starts proxying)
- **Wave 3**: Apps & Ingresses (Beszel Hub, Argo CD Tailscale Ingress)

---

## Useful Day-1 Commands

```bash
# Check your node status
kubectl get nodes

# See all running pods across every namespace
kubectl get pods -A

# Inspect Argo CD Applications and sync health
kubectl get applications -n argocd

# Check if External Secrets synced properly from AWS SSM
kubectl get externalsecrets -A

# View logs for a pod
kubectl logs -n beszel deploy/beszel-hub -f
```
