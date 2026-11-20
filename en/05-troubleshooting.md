# Troubleshooting and Diagnostics

<div align="right">
  <b>🌐 Language / Dil:</b> <a href="../05-sorun-giderme.md">🇹🇷 Türkçe</a> | 🇬🇧 <b>English</b>
</div>

---

| Field | Value |
|---|---|
| **Document ID** | ZT-005 |
| **Version** | 2.0 (Cloudflare One & WARP v2026.7+) |
| **Release Date** | 2026-11-20 |
| **Related Docs** | [ZT-002](02-cloudflare-setup.md), [ZT-004](04-warp-setup.md), [ZT-006](06-automation.md) |

## 1. Objective

This document provides a structured diagnostic procedure and symptom-to-resolution matrix for connectivity, tunnel protocol (WireGuard vs. MASQUE), and Discord voice/WebRTC (`RTC Connecting`) issues.

## 2. Initial Diagnostics

Run the following commands in PowerShell to inspect your current client state:

```powershell
warp-cli --accept-tos status
warp-cli --accept-tos registration show
warp-cli --accept-tos settings
```

Or run the automated verification script:

```powershell
.\scripts\Verify-DiscordTunnel.ps1
```

## 3. Symptom, Root Cause, and Resolution Matrix

| Symptom | Probable Root Cause | Resolution |
|---|---|---|
| Client fails with **"Forbidden"** or **"Unable to connect"** during login | `Device enrollment permissions` is not attached to an Access policy, or your email does not match the policy | [ZT-002](02-cloudflare-setup.md) Sections 4 & 5: Attach your `Allow` policy under `Team & Resources > Devices > Management` |
| WARP shows `Connected`, but Discord does not load at all | Split Tunnel is still in `Exclude` mode, or Discord routes have not synced to the client | [ZT-002](02-cloudflare-setup.md) Section 6.3: Set Split Tunnels to `Include IPs and domains`, then run `warp-cli disconnect` and `warp-cli connect` |
| Discord loads in the browser, but the desktop app is stuck on `"Checking for updates"` / `"Update Failed"` | Stale/poisoned Windows DNS cache or missing `updates.discord.com` rule | Run `ipconfig /flushdns`, completely quit Discord from the system tray / Task Manager, and relaunch |
| Voice channel hangs on **"RTC Connecting"** or has no audio | Tunnel protocol is still `WireGuard` (`UDP/2408`) and throttled by ISP, **or** `66.22.192.0/18` voice IP blocks are missing | 1. Switch tunnel protocol to **`MASQUE (Recommended)`** ([ZT-002](02-cloudflare-setup.md) Section 6.2).<br/>2. Add the `66.22.x.x` voice blocks ([ZT-003](03-ip-and-dns.md) Section 4.3). |
| You can hear others, but your microphone does not transmit | Outbound UDP packets are dropped on WireGuard port `UDP/2408` | Change `Device tunnel protocol` to **MASQUE** (`HTTP/3 - UDP/443`) |
| Online games experience higher ping while WARP is connected | Split Tunnel mode was left on `Exclude` (tunneling 100% of system traffic) | Switch Split Tunnel mode to **`Include IPs and domains`** so only Discord traffic enters the tunnel |
| `discord.gg` invite links or external images/stickers fail to load | Missing `discord.gg`, `*.discordapp.net`, or `*.discord.media` rules | Apply the full 164-rule inventory using `Apply-DiscordZeroTrust.ps1` ([ZT-006](06-automation.md)) |
| Device does not appear in the Cloudflare dashboard | WARP is still in consumer (`1.1.1.1`) mode | Check `warp-cli registration show` and verify `Account type: Team` ([ZT-004](04-warp-setup.md) Section 4) |

## 4. Detailed Diagnostic Checks

### 4.1 Checking Active Tunnel Scope

```powershell
warp-cli --accept-tos tunnel host list
warp-cli --accept-tos tunnel ip list
```

If the list is empty or missing Discord routes, restart the WARP service to force a policy sync:

```powershell
Restart-Service -Name CloudflareWARP
```

### 4.2 Checking DNS Resolution

```powershell
Resolve-DnsName discord.com -Type A
Resolve-DnsName gateway.discord.gg -Type A
```

- If the result is empty, `0.0.0.0`, or `127.0.0.1`, DNS resolution is being intercepted (verify `Mode: WarpWithDnsOverHttps`).
- If the result returns `162.159.128.x` - `162.159.138.x`, DNS resolution is healthy.

### 4.3 Checking TCP 443 Reachability

```powershell
Test-NetConnection gateway.discord.gg -Port 443
Test-NetConnection discord.com -Port 443
```

`TcpTestSucceeded` must be `True`.

### 4.4 Verifying Tunnel Protocol (MASQUE vs. WireGuard)

```powershell
warp-cli --accept-tos settings | Select-String 'protocol|MASQUE'
```

If `WARP tunnel protocol: WireGuard` is displayed, switch to **MASQUE** in the dashboard (`Devices > Device profiles > Default > Edit profile settings`) or run `Apply-DiscordZeroTrust.ps1 -Protocol masque`, then reconnect:

```powershell
warp-cli --accept-tos disconnect
Start-Sleep -Seconds 2
warp-cli --accept-tos connect
```

## 5. Clean Restart Procedure

Most transient connection issues are resolved by following this exact 6-step sequence:

1. Disconnect WARP: `warp-cli --accept-tos disconnect`
2. Flush Windows DNS cache: `ipconfig /flushdns`
3. Quit Discord completely (`Stop-Process -Name Discord -Force -ErrorAction SilentlyContinue`)
4. Reconnect WARP: `warp-cli --accept-tos connect`
5. Confirm status: `warp-cli --accept-tos status` (`Connected`)
6. Relaunch Discord.

## 6. Related Documents

- Dashboard Configuration: [02-cloudflare-setup.md](02-cloudflare-setup.md)
- WARP Client Setup: [04-warp-setup.md](04-warp-setup.md)
- Automated API Deployment: [06-automation.md](06-automation.md)
