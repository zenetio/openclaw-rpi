# 🔐 OpenClaw Secure LAN Access Setup (RPi + Multi-Device Access)

## 📌 Overview
This guide provides a **secure configuration** for running OpenClaw on a Raspberry Pi while allowing access from multiple devices:

- PC
- Laptop
- Mobile phone
- Other Raspberry Pi devices

The setup ensures:
- Controlled LAN access
- Strong authentication
- Firewall protection
- Scalability for future VPN integration

---

## 🧱 Architecture

```
Devices (PC / Laptop / Phone / RPi)
        ↓
   Local Network (LAN)
        ↓
   🔐 Firewall (UFW rules)
        ↓
   🔐 Token Authentication
        ↓
   OpenClaw (Raspberry Pi)
```

---

## ⚙️ Step 1 — Configure OpenClaw (LAN Access)

Edit your `openclaw.json`:

```json
"gateway": {
  "port": 18789,
  "mode": "local",
  "bind": "lan",
  "auth": {
    "mode": "token",
    "token": "YOUR-STRONG-TOKEN"
  }
}
```

---

## 🔐 Step 2 — Generate a Strong Token

Run on the Raspberry Pi:

```bash
openssl rand -hex 32
```

Example output:

```
c8f4a1b9d3e7...
```

Replace in config:

```json
"token": "c8f4a1b9d3e7..."
```

---

## 🔁 Step 3 — Restart OpenClaw

```bash
pkill -f openclaw
openclaw dashboard --no-open
```

---

## 🔥 Step 4 — Install and Configure Firewall (UFW)

### Install UFW

```bash
sudo apt install ufw -y
```

### Set default policies

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Allow SSH access

```bash
sudo ufw allow 22
```

---

## 🟢 Step 5 — Allow Trusted Devices Only

Replace IPs with your actual devices:

```bash
sudo ufw allow from 192.168.100.100 to any port 18789   # PC
sudo ufw allow from 192.168.100.101 to any port 18789   # Laptop
sudo ufw allow from 192.168.100.102 to any port 18789   # Phone
sudo ufw allow from 192.168.100.103 to any port 18789   # Other RPi
```

### Block all others

```bash
sudo ufw deny 18789
```

---

## 🚀 Step 6 — Enable Firewall

```bash
sudo ufw enable
```

### Verify rules

```bash
sudo ufw status numbered
```

---

## 📱 Step 7 — Access OpenClaw

From any allowed device:

```
http://<RPI_IP>:18789/#token=YOUR-TOKEN
```

Example:

```
http://192.168.100.101:18789/#token=c8f4a1b9d3e7...
```

---

## ⚠️ Handling Dynamic IPs (Phones)

### Option A — Reserve IP (Recommended)
Configure static DHCP in your router.

### Option B — Allow subnet (Less secure)

```bash
sudo ufw allow from 192.168.100.0/24 to any port 18789
```

---

## 🔐 Optional Hardening

### Install Fail2Ban

```bash
sudo apt install fail2ban -y
```

### Rate limiting

```bash
sudo ufw limit 18789
```

---

## 🧠 Best Practice Recommendations

### Current Setup
- LAN binding + UFW restrictions
- Strong authentication token

### Future Upgrade (Recommended)

Implement **WireGuard VPN**:

```
PC ↔ WireGuard ↔ RPi
Laptop ↔ WireGuard ↔ RPi
Phone ↔ WireGuard ↔ RPi
```

Benefits:
- Encrypted communication
- No need for LAN exposure
- Scalable for multiple devices

---

## ✅ Summary

✔ OpenClaw bound to LAN
✔ Strong token authentication
✔ Firewall restricts access to trusted devices
✔ Secure multi-device access achieved

---

## 📌 Next Steps

- Integrate WireGuard VPN
- Automate deployment across multiple RPis
- Add monitoring/logging for access control

---

---

## 🧠 Model Selection for OpenClaw (Critical)

### Problem Observed
When using `llama3.2`, prompts like **"Who are you?"** returned only:
- tool execution blocks (e.g., `memory_search`)
- JSON/tool outputs
- ❌ **no final natural-language answer**

### Root Cause
OpenClaw uses an **agent + tools loop**:

1. Model decides to call a tool
2. Tool executes
3. Tool result is returned to the model
4. Model must generate a **final human-readable answer**

Small / less capable models often fail at **step 4**.

#### What `llama3.2` did
- ✔ Called tools
- ✔ Received results
- ❌ Did NOT produce final answer
- ❌ Emitted raw tool-call / JSON instead

This is a known limitation of smaller models in **agentic workflows**.

---

### Why `qwen2.5:7b` Works

`qwen2.5:7b` correctly handles the full agent loop:

- ✔ Understands when to call tools
- ✔ Consumes tool output
- ✔ Produces final natural-language response
- ✔ Follows structured tool-calling patterns

It has:
- better instruction-following
- stronger reasoning
- more reliable tool integration behavior

---

### Recommendation

For OpenClaw (agents + tools), use:

- ✅ `qwen2.5:7b` (recommended baseline)
- ✅ `llama3.1:8b`

Avoid using smaller models like:
- ⚠ `llama3.2` (unstable for tool workflows)

---

### Rule of Thumb

| Use Case | Model Type |
|----------|-----------|
| Simple chat | Small models OK |
| Agents + tools | **7B+ models required** |
| Multi-agent systems | Prefer strong reasoning models |

---

### Practical Tip

If you see:
- tool output but no answer
- raw JSON in chat

👉 It is **almost always a model limitation**, not a configuration issue.

---

**Author:** Secure IoT Deployment Guide for OpenClaw

