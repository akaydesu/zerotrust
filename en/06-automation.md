# Automated Configuration via Cloudflare API and PowerShell

<div align="right">
  <b>🌐 Language / Dil:</b> <a href="../06-otomasyon.md">🇹🇷 Türkçe</a> | 🇬🇧 <b>English</b>
</div>

---

| Field | Value |
|---|---|
| **Document ID** | ZT-006 |
| **Version** | 2.0 |
| **Release Date** | 2026-11-20 |
| **Related Docs** | [ZT-002](02-cloudflare-setup.md), [ZT-003](03-ip-and-dns.md), [ZT-004](04-warp-setup.md) |
| **Prerequisite** | [ZT-002](02-cloudflare-setup.md) Sections 3–6 completed and WARP enrolled into your team |

## 1. Objective

This document describes how to apply the 164-rule Discord Split Tunnel (`Include`) inventory and the **MASQUE** tunnel protocol setting automatically via the Cloudflare API using a single PowerShell command. This eliminates the tedious process of manually entering 164 entries in the web UI and ensures an idempotent, backed-up configuration.

## 2. Key Features

- **Preserves Existing Rules (Idempotent):** Any existing non-Discord rules in your Split Tunnel Include list are **preserved**; the 164 Discord rules are merged cleanly without duplicates no matter how many times you run the script.
- **Automatic Timestamped Backups:** Before modifying anything, the script saves your current cloud Include list to `scripts/backup/include-<timestamp>.json`.
- **Automatically Sets Protocol to MASQUE:** Updates your device profile tunnel protocol to `masque` (`HTTP/3 - UDP/443`) and reconnects the local WARP client.

## 3. Creating a Cloudflare API Token

### 3.1 Token Creation Steps

1. Sign in to <https://dash.cloudflare.com>.
2. Go to **My Profile > API Tokens** (top right menu) or **Manage account > Account API tokens** (left sidebar).
3. Click **Create Token > Create Custom Token (Get started)**.
4. Configure the token permissions as follows:

| Field | Value |
|---|---|
| **Token name** | `zero-trust-discord-setup` |
| **Permissions** | `Account` → `Zero Trust` → `Edit` |
| **Account Resources** | `Include` → Your Account |
| **TTL** | Optional (e.g., 1 day) |

5. Click **Continue to summary > Create Token** and copy the token (it is only displayed once).

### 3.2 Token Security & Revocation

Provide the token via the script's secure prompt (`API Token:`) or a temporary environment variable. Never commit the token to source control. Once the script finishes, **Delete** the token in the Cloudflare dashboard.

---

## 4. Scripts Overview

| File | Function |
|---|---|
| [`scripts/Apply-DiscordZeroTrust.ps1`](../scripts/Apply-DiscordZeroTrust.ps1) | Merges the 164 Discord rules with your existing Include list, sets protocol to **MASQUE**, and reconnects WARP |
| [`scripts/Verify-DiscordTunnel.ps1`](../scripts/Verify-DiscordTunnel.ps1) | Runs automated PASS/FAIL checks for WARP service, Team enrollment, MASQUE protocol, Split Tunnel rules, DNS, TCP 443, and HTTPS API |
| [`scripts/discord-routes.txt`](../scripts/discord-routes.txt) | Complete 164-rule inventory (84 domains + 76 IPv4 + 4 IPv6) |

---

## 5. Step-by-Step Execution

### 5.1 Dry Run Preview (`-DryRun` — No API Token Required)

Preview the diff between your current local WARP Include list and the 164-rule target list without making any changes:

```powershell
cd scripts
.\Apply-DiscordZeroTrust.ps1 -DryRun
```

### 5.2 Applying the Configuration

```powershell
.\Apply-DiscordZeroTrust.ps1
```

The script will prompt you securely for your Cloudflare API Token. Alternatively, pass it via environment variable:

```powershell
$env:CF_API_TOKEN = "your-api-token-here"
.\Apply-DiscordZeroTrust.ps1
```

### 5.3 Verifying the Tunnel

```powershell
.\Verify-DiscordTunnel.ps1
```

## 6. Restoring from Backup (Rollback)

Every execution writes a backup to `scripts/backup/include-<timestamp>.json`. To roll back to a previous list:

```powershell
$acc   = "<32-char-account-id>"
$token = "<api-token>"
$h     = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$old   = Get-Content .\scripts\backup\include-20261120-050000.json -Raw
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $old
```

## 7. Related Documents

- Dashboard Configuration: [02-cloudflare-setup.md](02-cloudflare-setup.md)
- Address Inventory: [03-ip-and-dns.md](03-ip-and-dns.md)
- Troubleshooting Guide: [05-troubleshooting.md](05-troubleshooting.md)
