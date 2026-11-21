#!/usr/bin/env bash
# Run this on the Raspberry Pi (`pi`) AFTER bootstrapping `pc` with bootstrap.sh.
#
# First, get the join token on `pc`:
#   sudo cat /var/lib/rancher/k3s/server/node-token
#
# Then run on `pi`:
#   K3S_URL="https://<PC_LAN_OR_TAILSCALE_IP>:6443" \
#   K3S_TOKEN="<NODE_TOKEN>" \
#   ./join-pi.sh
set -euo pipefail

: "${K3S_URL:?Set K3S_URL to https://<pc-ip>:6443}"
: "${K3S_TOKEN:?Set K3S_TOKEN from /var/lib/rancher/k3s/server/node-token on pc}"

echo "==> Joining this Raspberry Pi as a k3s worker node to ${K3S_URL}"
curl -sfL https://get.k3s.io | K3S_URL="${K3S_URL}" K3S_TOKEN="${K3S_TOKEN}" sh -

echo "==> Done! Verify on pc with: kubectl get nodes -o wide"
