# OpenClaw on Raspberry Pi 5 + Ollama on PC (LAN Setup Guide)

## Overview

This guide walks you through setting up the following architecture:

- **PC** → Runs Ollama + Local LLM
- **Raspberry Pi 5** → Runs OpenClaw agent
- **LAN** → OpenClaw connects to Ollama via HTTP

```
[Raspberry Pi 5]
  OpenClaw Agent
        |
        |  HTTP (LAN)
        v
[PC]
  Ollama Server + LLM
```

---

## Prerequisites

### Raspberry Pi 5
- Raspberry Pi OS (64-bit recommended)
- Internet access
- curl installed

### PC (Windows / Linux / macOS)
- Ollama installed
- Enough RAM/VRAM for chosen model

---

## Step 1 — Install Ollama on PC

Download and install Ollama:

👉 https://ollama.com

Verify installation:

```bash
ollama --version
```

---

## Step 2 — Expose Ollama to LAN

By default, Ollama listens only on `localhost`.
You must expose it to your local network.

### Linux

Edit service config:

```bash
sudo systemctl edit ollama
```

Add:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_CONTEXT_LENGTH=64000"
```

Restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

---

### Windows

Set environment variable:

```
OLLAMA_HOST=0.0.0.0:11434
```

Restart Ollama application.

---

## Step 3 — Pull a Model

Example models:

```bash
ollama pull llama3.1:8b
```

```bash
ollama pull gemma3:4b
```

```bash
ollama pull granite3.3:8b
```

---

## Step 4 — Verify Ollama API

On the PC:

```bash
curl http://localhost:11434/api/tags
```

Expected: list of models

---

## Step 5 — Get PC IP Address

### Linux/macOS

```bash
ip a
```

### Windows

```bash
ipconfig
```

Example result:

```
192.168.1.50
```

---

## Step 6 — Test from Raspberry Pi

```bash
curl http://192.168.100.103:11434/api/tags
```

If this works → networking is OK

---

## Step 7 — Install OpenClaw on Raspberry Pi

> **Note:** The installer requires `sudo` privileges to install system dependencies (like Node.js). Ensure your user is in the `sudo` group.

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

If you see `user ... may not run sudo`, switch to an admin user or add your user to sudoers (requires logging in as a user with sudo rights first):

```bash
sudo usermod -aG sudo $USER
# Then logout and login again
```

---

## Step 8 — Run OpenClaw Onboarding

> **Crucial:** Run this step as your **regular user** (`u-reg`), **NOT** as `root` (do not use `sudo`). OpenClaw installs a user-level service (`systemd --user`) which fails if run as root.

First, enable "lingering" so the service keeps running after you disconnect.
This command requires sudo. If you get `u-reg is not in the sudoers file`, you must log in as an admin user (like `pi`) to run it, or run `su - pi` first to switch users, then:

```bash
sudo loginctl enable-linger u-reg
```

*(Replace `u-reg` with your actual username if different)*

Then, run the onboarding command as your regular user (`u-reg`):

### Non-interactive setup (optional)

Use this command for a headless installation (e.g., over SSH). It configures OpenClaw to listen on the LAN and installs the background service.

```bash
openclaw onboard --non-interactive \
  --auth-choice ollama \
  --custom-base-url "http://192.168.1.50:11434" \
  --custom-model-id "llama3.2" \
  --gateway-bind lan \
  --install-daemon \
  --accept-risk
```

> **Note:**
> - Ensure you Use `--non-interactive` (with dashes).
> - The `--gateway-bind lan` flag makes the agent accessible on your network.
> - If you see `Failed to discover Ollama models` but it proceeds to "Downloading" or "Default Ollama model", it might be a temporary timeout. If the script finishes successfully, you can ignore the initial error.

---

### Interactive Setup (Alternative)

If you prefer the interactive wizard:

```bash
openclaw onboard --install-daemon
```

1. Select **Local gateway (this machine)**.
2. Select **Manual** configuration.
   - *QuickStart* often defaults to `localhost`, which won't work for your LAN setup.
3. Select **Ollama** as the authentication provider.
4. **Gateway Bind:** Select `LAN (0.0.0.0)` or `Auto`.
5. Select **Ollama** from the list of Model/auth providers.
6. Enter the PC's IP address when prompted for the **Base URL**:
   ```
   Base URL: http://192.168.1.50:11434
   ```
7. Select **Local** for the Ollama mode.
8. **Workspace Directory:** Press Enter to accept the default (`/home/u-reg/.openclaw/workspace`).


---

## Step 9 — Verify OpenClaw

```bash
openclaw gateway status
```

```bash
openclaw models list
```

Set default model:

```bash
openclaw models set ollama/llama3.1:8b
```

---

## Step 10 — Open Dashboard

```bash
openclaw dashboard
```

For remote access from your PC, use the tokenized URL:

```bash
openclaw dashboard --no-open
```

Copy the full URL exactly as printed, including the `#token=...` suffix.

If you connect from your PC over SSH, create a tunnel first:

```bash
ssh -N -L 18789:127.0.0.1:18789 u-reg@raspberrypi
```

Then open the `Dashboard URL` printed by `openclaw dashboard --no-open` on the Pi.

> **Important:** If you open the dashboard without the token, the chat UI will disconnect with `unauthorized: gateway token missing`.

---

## Recommended Models

### Lightweight (Best for starting)
- `gemma3:4b`

### Balanced
- `llama3.1:8b`
- `granite3.3:8b`

### Heavy (High-end PC only)
- `command-r:35b`

---

## Performance Tips

- Use **≥64K context** for agent workflows
- Ensure PC has enough RAM/VRAM
- Prefer wired Ethernet for stability
- Keep Pi and PC on same subnet

---

## Troubleshooting

### "Failed to discover Ollama models: TypeError: fetch failed"

This error means the Raspberry Pi cannot connect to your PC's Ollama server on port 11434.

**1. Check if Ollama is listening on all interfaces (0.0.0.0)**
On your PC, run:
- **Windows:** `netstat -an | findstr 11434`
- **Linux/macOS:** `netstat -an | grep 11434`

If you see `127.0.0.1:11434`, Ollama is only listening locally. Revisit **Step 2** to set `OLLAMA_HOST=0.0.0.0:11434`.
If you see `0.0.0.0:11434` or `[::]:11434`, it is correctly configured.

**2. Check PC Firewall**
Your PC's firewall might be blocking the connection.
- **Windows:** Allow port `11434` through Windows Defender Firewall (Inbound Rules).
- **Linux:** Check `ufw` or `iptables` (e.g., `sudo ufw allow 11434/tcp`).

**3. Verify Connectivity from Pi**
Run this command from your Raspberry Pi to test the connection:
```bash
curl -v http://192.168.100.103:11434/api/tags
```
*(Replace `192.168.100.103` with your actual PC IP)*
- If this times out, it's likely a firewall issue or wrong IP.
- If it works, OpenClaw should work too.

**4. If curl works but OpenClaw fails:**
This usually means Node.js is trying to use a proxy.
- **Check Proxy:** Node.js respects `HTTP_PROXY` / `http_proxy`.
- **Fix:** Add your PC's IP to the `NO_PROXY` environment variable before running OpenClaw:
  ```bash
   export NO_PROXY=192.168.100.103
  openclaw onboard ...
  ```
- **Check Model Name:** You requested `llama3.1:8b` but your `curl` output might show it's missing (e.g., you only have `llama3.2`). Using a missing model ID can sometimes look like a connection failure during verification. Try using a model that appears in your `curl` list.

---

### "Systemd user services are unavailable"

If you see this error, your Linux user session doesn't support background services (common on minimal Pi OS installs).

**Option 1: Fix Systemd (Recommended)**
1. Install missing dependency:
   ```bash
   sudo apt-get install -y dbus-user-session
   ```
2. Reboot the Pi:
   ```bash
   sudo reboot
   ```
3. Log in as `u-reg` and try the `openclaw onboard ... --install-daemon` command again.

**Option 2: Run Manually (Fallback)**
If systemd still fails, configure it first, then run the gateway manually:

1. Run configuration (without installing daemon):
   ```bash
   openclaw onboard --non-interactive \
     --auth-choice ollama \
       --custom-base-url "http://192.168.100.103:11434" \
     --custom-model-id "llama3.2" \
     --gateway-bind lan \
     --accept-risk
   ```
   *(Note: This might still show a "gateway closed" error at the end. Ignore it.)*

2. Start the gateway in the background manually:
   ```bash
   nohup openclaw gateway run > openclaw.log 2>&1 &
   ```

---

### Cannot connect from Pi

- Check firewall on PC
- Ensure Ollama bound to `0.0.0.0`
- Verify IP address

---

### Model not responding correctly

- Avoid `/v1` endpoint
- Try different model
- Increase context length

---

### "Model context window too small (8192 tokens). Minimum is 16000."

OpenClaw blocks models whose effective context window is below `16000` tokens.

That value can come from:

- The Ollama model metadata discovered by OpenClaw
- An explicit `contextWindow` override in `~/.openclaw/openclaw.json`
- An `agents.defaults.contextTokens` cap in `~/.openclaw/openclaw.json`

Fix it in this order:

1. Check whether OpenClaw is capping the context:
    - Open `~/.openclaw/openclaw.json`
    - If you see `agents.defaults.contextTokens: 8192`, raise it to at least `16000` or remove it.

2. If the model itself is being reported as `8192`, add an explicit override in `~/.openclaw/openclaw.json`:

   Put this under the top-level `models.providers.ollama` section.
   Do **not** put it under `agents.defaults.models`.

    ```json5
    {
       "models": {
          "providers": {
             "ollama": {
                "baseUrl": "http://192.168.100.103:11434",
                "api": "ollama",
                "models": [
                   {
                      "id": "llama3.2",
                      "name": "llama3.2",
                      "contextWindow": 16384,
                      "maxTokens": 4096
                   }
                ]
             }
          }
       }
    }
    ```

3. Restart OpenClaw after the config change:

    ```bash
    openclaw gateway stop
    openclaw gateway run
    ```

    If you are using the user systemd service instead of a manual run:

    ```bash
    systemctl --user restart openclaw-gateway
    ```

4. If the error remains, choose an Ollama model that already reports `16000+` tokens.

---

### "Disconnected from gateway: unauthorized: gateway token missing"

This means the dashboard was opened without the gateway auth token.

Fix:

1. On the Raspberry Pi, run:
   ```bash
   openclaw dashboard --no-open
   ```
2. Copy the full `Dashboard URL`, including `#token=...`.
3. If connecting from your PC, use an SSH tunnel:
   ```bash
   ssh -N -L 18789:127.0.0.1:18789 u-reg@raspberrypi
   ```
4. Open the printed URL in your PC browser.

Do **not** browse directly to `http://<pi-ip>:18789/` without the token.

---

### Slow performance

- Use smaller model
- Check CPU/GPU usage on PC

---

## Summary

You now have:

- Raspberry Pi running OpenClaw
- PC running Ollama + LLM
- Communication over LAN

This setup allows you to:

- Offload heavy inference to PC
- Keep Pi lightweight
- Build scalable agent-based systems

---

## Next Steps

- Add multiple agents
- Integrate tools (MQTT, WebSockets, APIs)
- Add observability (OpenTelemetry)
- Deploy SLM fallback on Pi

---

**End of Guide**
