#!/usr/bin/env bash
set -euo pipefail

# Resolve all paths relative to this script so it can be run from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/configs/trusted_devices.example.env"
SAMPLE_JSON="$REPO_ROOT/configs/openclaw.sample.json"
TARGET_DIR="$HOME/.openclaw"
TARGET_JSON="$TARGET_DIR/openclaw.json"

# Refuse to continue if the device trust/config env file is missing.
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

# Load the trusted device settings that provide values for the config template.
# shellcheck disable=SC1090
source "$ENV_FILE"

# Fail early with a clear message if the required secrets/hosts are not set.
: "${PC_OLLAMA_IP:?Set PC_OLLAMA_IP in $ENV_FILE}"
: "${OPENCLAW_TOKEN:?Set OPENCLAW_TOKEN in $ENV_FILE}"

# Ensure the runtime config directory exists under the current user's home.
mkdir -p "$TARGET_DIR"

# Fill the sample JSON template with environment-specific values.
python3 - <<PY
from pathlib import Path
text = Path(r"$SAMPLE_JSON").read_text()
text = text.replace("PC_OLLAMA_IP", r"$PC_OLLAMA_IP")
text = text.replace("OPENCLAW_TOKEN", r"$OPENCLAW_TOKEN")
Path(r"$TARGET_JSON").write_text(text)
print(f"Wrote {Path(r'$TARGET_JSON')}")
PY

# Install OpenClaw on the Raspberry Pi if it is not already available.
if ! command -v openclaw >/dev/null 2>&1; then
  echo "OpenClaw not found. Installing..."
  curl -fsSL https://openclaw.ai/install.sh | bash
fi

# Apply the local firewall rules expected by this deployment.
chmod +x "$SCRIPT_DIR/setup_firewall.sh"
"$SCRIPT_DIR/setup_firewall.sh"

# Stop any existing instance so the dashboard restarts with the new config.
echo "Stopping any existing OpenClaw process..."
pkill -f openclaw || true

# Start the dashboard service without launching a browser on the Pi itself.
echo "Starting OpenClaw dashboard..."
openclaw dashboard --no-open
