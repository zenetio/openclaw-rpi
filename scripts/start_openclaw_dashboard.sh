#!/usr/bin/env bash
set -euo pipefail
pkill -f openclaw || true
openclaw dashboard --no-open
