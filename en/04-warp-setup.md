# WARP Client Installation and Connection Verification

<div align="right">
  <b>🌐 Language / Dil:</b> <a href="../04-warp-kurulumu.md">🇹🇷 Türkçe</a> | 🇬🇧 <b>English</b>
</div>

---

| Field | Value |
|---|---|
| **Document ID** | ZT-004 |
| **Version** | 2.0 (Cloudflare One Client / WARP v2026.7+) |
| **Release Date** | 2026-11-20 |
| **Estimated Time** | 5 - 10 minutes |
| **Related Docs** | [ZT-002](02-cloudflare-setup.md), [ZT-003](03-ip-and-dns.md), [ZT-005](05-troubleshooting.md) |

## 1. Objective

This document explains how to install the Cloudflare WARP (Cloudflare One Client `v2026.7+`) desktop application on Windows, enroll it into your Zero Trust organization configured in [ZT-002](02-cloudflare-setup.md), and verify that Discord traffic is actively routed over the **MASQUE** tunnel.

## 2. Prerequisites

- [ZT-002](02-cloudflare-setup.md) completed (`Team domain`, email Access policy, `Device enrollment permissions`, Split Tunnel `Include` mode, and `MASQUE` protocol).
- Local Administrator privileges on the Windows machine.
- Keep the Discord application closed until enrollment is verified.

---

## 3. Installing the WARP Client

### 3.1 Downloading the Installer

1. Visit <https://one.one.one.one/> or navigate to **`Zero Trust > Settings > Downloads`** in your Cloudflare dashboard.
2. Download the Windows installer (`Cloudflare_WARP_Release-x64.msi`).

### 3.2 Running the Installer & Checking the Service

1. Run the `.msi` installer and complete the setup wizard.
2. Verify in PowerShell that the `CloudflareWARP` service is running and check the client version (`2026.7+`):

```powershell
Get-Service -Name CloudflareWARP | Select-Object Status, StartType
warp-cli --version
```

Expected output: `Status: Running`, `StartType: Automatic`, version `warp-cli 2026.7.x`.

---

## 4. Enrolling into Your Zero Trust Organization

When first installed, WARP starts in consumer (`1.1.1.1`) mode. To activate your Split Tunnel (`Include`) rules and **MASQUE** protocol settings, enroll the client into your Zero Trust team.

### 4.1 Enrollment via GUI

1. Click the **Cloudflare WARP** icon in the Windows system tray (bottom right).
2. Click the **Settings (⚙️ gear)** icon in the bottom right corner of the popup and select **Preferences**.
3. Switch to the **Account** tab at the top.
4. Click **Login with Cloudflare Zero Trust** in the bottom left.
5. In the **"What is your team name?"** prompt, enter the **team name** you configured in [ZT-002](02-cloudflare-setup.md) Section 3.2 (enter only `<team-name>` without `.cloudflareaccess.com`) and click **Continue**.
6. Your default browser will open `https://<team-name>.cloudflareaccess.com`:
   - Enter the **email address** permitted by your Access policy in [ZT-002](02-cloudflare-setup.md) Section 4.1 and click **Send me a code**.
   - Enter the 6-digit one-time PIN sent to your inbox.
   - Approve the browser prompt to open **Cloudflare WARP / Cloudflare One Client**.
7. Once enrolled, the WARP window will switch to **`Zero Trust`** mode and display **`Connected`**.

### 4.2 Fast Enrollment via Command Line (`warp-cli`)

Alternatively, you can initiate enrollment directly from PowerShell without opening the GUI menus:

```powershell
warp-cli --accept-tos teams-enroll <team-name>
warp-cli --accept-tos connect
```

---

## 5. Verifying Connection and Protocol Settings

### 5.1 Automated Verification Script

Run the included verification script to test the service, team registration, tunnel protocol, Split Tunnel rules, DNS resolution, TCP 443 reachability, and HTTPS API response in one command:

```powershell
.\scripts\Verify-DiscordTunnel.ps1
```

### 5.2 Manual CLI Verification (`warp-cli`)

1. **Check Team Registration:**
   ```powershell
   warp-cli --accept-tos registration show
   ```
   Expected output:
   ```text
   Account type: Team
   Organization: <team-name>
   ```

2. **Check Connection & Network Health:**
   ```powershell
   warp-cli --accept-tos status
   ```
   Expected output:
   ```text
   Status update: Connected
   Network: healthy
   ```

3. **Check Protocol (MASQUE & Post-Quantum) and Split Tunnel Rules:**
   ```powershell
   warp-cli --accept-tos settings
   ```
   Verify the following fields in the output:
   - `Mode: WarpWithDnsOverHttps`
   - `WARP tunnel protocol: MASQUE` (HTTP/3 `UDP/443` active)
   - `Post-quantum support for MASQUE: Enabled (downgrades allowed)`
   - `Include mode, with hosts/ips:` listing your Discord domains and IP blocks.

4. **List Active Included IPs and Domains:**
   ```powershell
   warp-cli --accept-tos tunnel ip list
   warp-cli --accept-tos tunnel host list
   ```

---

## 6. Functional Verification (Discord Test)

1. Open `https://discord.com/app` in your browser to confirm web access.
2. Launch the **Discord desktop application**.
3. Join a voice channel and confirm **`Voice Connected / RTC Connected`** with stable ping.
4. Verify that images, server icons, and `discord.gg` invite links load properly.

## 7. Unenrolling / Reverting to Consumer Mode

To remove the device from your Zero Trust organization:

```powershell
warp-cli --accept-tos disconnect
warp-cli --accept-tos registration delete
```

## 8. Related Documents

- Dashboard Configuration: [02-cloudflare-setup.md](02-cloudflare-setup.md)
- Troubleshooting Guide: [05-troubleshooting.md](05-troubleshooting.md)
- Automated API Deployment: [06-automation.md](06-automation.md)
