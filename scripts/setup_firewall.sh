#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/configs/trusted_devices.example.env"

# shellcheck disable=SC1090
source "$ENV_FILE"

sudo apt-get update -y
sudo apt-get install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp

IFS=',' read -ra IPS <<< "${TRUSTED_OPENCLAW_CLIENTS:-}"
for ip in "${IPS[@]}"; do
  ip_trimmed="$(echo "$ip" | xargs)"
  [[ -z "$ip_trimmed" ]] && continue
  echo "Allowing OpenClaw from $ip_trimmed"
  sudo ufw allow from "$ip_trimmed" to any port 18789 proto tcp
done

sudo ufw deny 18789/tcp || true
sudo ufw --force enable
sudo ufw status numbered
