# openclaw-rpi

`openclaw-rpi` is a small deployment and operations repository for running **OpenClaw on a Raspberry Pi** while using **Ollama on another machine in the same LAN** as the model backend.

This repository is not the OpenClaw application source code. It is a companion repo that collects:

- setup guides for a Raspberry Pi + Ollama LAN deployment
- sample OpenClaw configuration files
- helper scripts to deploy the config on the Pi
- firewall automation for restricting dashboard access to trusted devices
- a Windows helper script for starting Ollama with LAN access enabled

## What This Repository Is For

Use this repo if you want to:

- run the OpenClaw agent and dashboard on a Raspberry Pi
- keep model inference on a separate PC running Ollama
- expose OpenClaw to your local network instead of `localhost` only
- secure dashboard access with a token and basic firewall rules
- reuse a simple, repeatable setup instead of re-entering configuration by hand

The intended architecture is:

```text
[Raspberry Pi]
  OpenClaw agent + dashboard
          |
          | HTTP over LAN
          v
[PC]
  Ollama server + local model
```

## Repository Layout

- `configs/`
  - `openclaw.sample.json`: sample OpenClaw configuration template for an Ollama-backed LAN deployment
  - `trusted_devices.example.env`: example environment variables for trusted client IPs, Pi user, Ollama host IP, and dashboard token
- `docs/`
  - `open_claw_ollama_lan_setup_guide.md`: step-by-step guide for the Pi + PC LAN setup
  - `open_claw_secure_lan_access_setup.md`: hardening guidance for token auth, UFW rules, and multi-device access
- `scripts/`
  - `deploy_rpi_openclaw.sh`: writes the runtime config, installs OpenClaw if needed, applies firewall rules, and starts the dashboard
  - `setup_firewall.sh`: installs/configures UFW and allows only trusted client IPs to reach the OpenClaw dashboard port
  - `start_openclaw_dashboard.sh`: restarts the OpenClaw dashboard on the Pi
  - `windows/start_ollama_lan_32k.ps1`: starts Ollama on Windows bound to `0.0.0.0:11434` with a larger context length
- `diagrams/`
  - architecture references used by the documentation

## How It Works

The repo assumes this split:

- **Raspberry Pi** runs OpenClaw
- **Windows/Linux/macOS PC** runs Ollama
- OpenClaw is configured to call the Ollama HTTP API over the LAN
- OpenClaw dashboard access is protected with a token
- UFW rules on the Pi restrict dashboard access to explicitly allowed client IPs

The sample configuration in `configs/openclaw.sample.json` uses placeholders for:

- `PC_OLLAMA_IP`
- `OPENCLAW_TOKEN`

The deployment script fills those placeholders from `configs/trusted_devices.example.env` and writes the final runtime file to `~/.openclaw/openclaw.json` on the Raspberry Pi.

## Typical Workflow

1. Start Ollama on your PC and bind it to the LAN.
2. Pull the model you want to use in Ollama.
3. Copy and customize the example env/config values in this repo.
4. Run the deployment script on the Raspberry Pi.
5. Access the OpenClaw dashboard from an allowed device using the tokenized URL.

## Quick Start

If you already know the target IPs and want the shortest path to a working setup:

1. On the Windows PC running Ollama, start the server with LAN binding:

  ```powershell
  .\scripts\windows\start_ollama_lan_32k.ps1
  ```

2. Pull at least one model in Ollama, for example:

  ```powershell
  ollama pull qwen2.5:7b
  ```

3. On the Raspberry Pi, clone this repository and customize the example env file:

  ```bash
  cp configs/trusted_devices.example.env configs/trusted_devices.env
  ```

4. Edit `configs/trusted_devices.env` and set:

  - `TRUSTED_OPENCLAW_CLIENTS`
  - `PC_OLLAMA_IP`
  - `OPENCLAW_TOKEN`

5. Run the deployment script on the Raspberry Pi:

  ```bash
  chmod +x scripts/deploy_rpi_openclaw.sh
  ./scripts/deploy_rpi_openclaw.sh
  ```

6. Open the dashboard from an allowed device:

  ```text
  http://<RPI_IP>:18789/#token=<OPENCLAW_TOKEN>
  ```

For a fuller walkthrough, including onboarding details and troubleshooting, use `docs/open_claw_ollama_lan_setup_guide.md`.

## Recommended Entry Points

If you are setting this up from scratch, start here:

- `docs/open_claw_ollama_lan_setup_guide.md`

If your main concern is restricting access on the local network, read:

- `docs/open_claw_secure_lan_access_setup.md`

If you already understand the setup and just want to apply the config on the Pi, use:

- `scripts/deploy_rpi_openclaw.sh`

If you need to start Ollama on Windows so the Pi can reach it over the network, use:

- `scripts/windows/start_ollama_lan_32k.ps1`

## Configuration Notes

The sample config in this repo is opinionated for a local-network deployment:

- OpenClaw gateway binds to the LAN
- authentication mode is token-based
- the Ollama provider is exposed through its HTTP endpoint
- the default sample model is configured for Ollama-backed use

The example env file also defines a comma-separated allowlist of client IP addresses. Those addresses are used by the firewall script to permit dashboard access only from trusted devices.

## Security Scope

This repository is designed for **LAN access**, not public internet exposure.

The current hardening approach is:

- token authentication in OpenClaw
- UFW allow rules for selected client IPs
- default deny for other inbound access to the dashboard port

If you need access beyond the local network, a VPN approach such as WireGuard is the safer next step than exposing the service directly.

## Requirements

At a minimum, expect:

- a Raspberry Pi running a recent Raspberry Pi OS
- `bash`, `curl`, and `python3` on the Pi
- `sudo` access on the Pi for package installation and firewall setup
- Ollama installed on a separate machine with enough RAM/VRAM for your chosen model

## Improvements

- You can add the **lossless-claw** plugin to improve memory management in your OpenClaw deployment.

## License

This repository is licensed under the MIT License. See `LICENSE` for the full text.

## Summary

In practical terms, `openclaw-rpi` is a reproducible setup kit for a Raspberry Pi-hosted OpenClaw instance that talks to an Ollama server on your LAN, with configuration templates, deployment helpers, and basic network hardening included.