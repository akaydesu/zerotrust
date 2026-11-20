# Address and Domain Inventory

<div align="right">
  <b>🌐 Language / Dil:</b> <a href="../03-ip-ve-dns.md">🇹🇷 Türkçe</a> | 🇬🇧 <b>English</b>
</div>

---

| Field | Value |
|---|---|
| **Document ID** | ZT-003 |
| **Version** | 2.0 |
| **Release Date** | 2026-11-20 |
| **Total Entries** | 164 (84 Domains + 76 IPv4 + 4 IPv6) |
| **Related Docs** | [ZT-002](02-cloudflare-setup.md), [ZT-004](04-warp-setup.md), [ZT-006](06-automation.md) |

## 1. Objective

This document defines the destination inventory used in the Cloudflare Zero Trust Split Tunnel (**Include IPs and domains**) configuration. The inventory is provided in two tiers:
1. **Quick Setup Set (15 Entries):** Uses broad CIDR blocks to cover core Discord web and voice traffic for users entering rules manually in the dashboard.
2. **Full Inventory (164 Entries):** Covers all Discord subdomains, CDN endpoints, Google Cloud media storage, and voice/RTC blocks (`scripts/discord-routes.txt`, automatically deployable via `Apply-DiscordZeroTrust.ps1`).

## 2. Classification

| Group | Entry Count | Selector Type | Coverage |
|---|---:|---|---|
| **Domains** | 84 | `Domain` | Web, API, Gateway, CDN, updater, activities, and invite domains |
| **Cloudflare Anycast (IPv4)** | 32 | `IP Address` | Discord frontend, Gateway, and CDN blocks (`162.159.x`, `104.x`) |
| **Discord Voice / RTC (IPv4)** | 32 | `IP Address` | Voice, video, and screen sharing (WebRTC) endpoints (`66.22.x`) |
| **Google Cloud (IPv4)** | 11 | `IP Address` | Discord media/backend infrastructure on Google Cloud (`34.x`, `35.x`) |
| **IPv6** | 4 | `IP Address` | Cloudflare IPv6 blocks (optional) |
| **Other** | 1 | `IP Address` | Dedicated single endpoint (`198.244.231.90/32`) |
| **Total** | **164** | | |

![Split Tunnels Add Entries](../assets/screenshots/06-split-tunnels-selector.png)

---

## 3. Quick Setup Set (15 Entries — Recommended for Manual Entry)

| Entry | Selector Type | Scope |
|---|---|---|
| `162.159.128.0/19` | `IP Address` | `162.159.128.0 - 162.159.159.255`; covers all `162.159.x` Gateway/API entries |
| `66.22.192.0/18` | `IP Address` | `66.22.192.0 - 66.22.255.255`; covers all Discord Voice/RTC UDP blocks |
| `104.18.0.0/20` | `IP Address` | Cloudflare CDN block |
| `104.16.51.111/32` | `IP Address` | Static CDN endpoint |
| `104.18.48.115/32` | `IP Address` | Static CDN endpoint |

### 3.1 Quick Set — Domains (`Selector: Domain` — 10 Entries)

```text
discord.com
*.discord.com
discord.gg
*.discord.gg
discordapp.com
*.discordapp.com
discordapp.net
*.discordapp.net
discord.media
*.discord.media
```

### 3.2 Quick Set — IP & CIDR (`Selector: IP Address` — 5 Entries)

```text
162.159.128.0/19
66.22.192.0/18
104.18.0.0/20
104.16.51.111/32
104.18.48.115/32
```

---

## 4. Full Inventory (164 Entries)

This list matches `scripts/discord-routes.txt`.

### 4.1 Domains (`Selector: Domain` — 84 Entries)

```text
*.bigbeans.solutions
*.daveprotocol.com
*.dis.gd
*.discord-activities.com
*.discord.co
*.discord.com
*.discord.design
*.discord.dev
*.discord.fr
*.discord.gg
*.discord.gift
*.discord.gifts
*.discord.media
*.discord.new
*.discord.store
*.discord.tools
*.discordactivities.com
*.discordapp.com
*.discordapp.io
*.discordapp.net
*.discordcdn.com
*.discordmedia.com
*.discordmerch.com
*.discordpartygames.com
*.discordsays.com
*.discordsez.com
*.discordstatus.com
*.discordusercontent.com
*.updates.discord.com
*.watchanimeattheoffice.com
airhorn.solutions
airhornbot.com
bigbeans.solutions
canary.discord.com
cdn.discordapp.com
cdn.discordapp.net
click.discord.com
collector.discord.com
daveprotocol.com
dfr.gg
dis.gd
discord-activities.com
discord-attachments-uploads-prd.storage.googleapis.com
discord.app
discord.co
discord.com
discord.design
discord.dev
discord.fr
discord.gg
discord.gift
discord.gifts
discord.media
discord.new
discord.store
discord.tools
discordactivities.com
discordapp.com
discordapp.io
discordapp.net
discordcdn.com
discordmerch.com
discordpartygames.com
discordsays.com
discordsez.com
discordstatus.com
dl.discordapp.net
fonts.discord.com
gateway-us-east1-b.discord.gg
gateway.discord.gg
gateway.discord.media
i.dis.gd
images-ext-1.discordapp.net
images-ext-2.discordapp.net
media.discordapp.net
ptb.discord.com
push.discord.com
remote-auth-gateway.discord.gg
software-update.discord.com
status.discord.com
support.discord.com
updates.discord.com
versions.discord.com
watchanimeattheoffice.com
```

### 4.2 Cloudflare Anycast, IPv4 (`Selector: IP Address` — 32 Entries)

```text
104.16.51.111/32
104.18.0.0/20
104.18.48.115/32
162.159.128.0/19
162.159.128.0/24
162.159.128.0/25
162.159.128.233/32
162.159.128.234/31
162.159.128.236/30
162.159.128.240/28
162.159.129.0/24
162.159.129.233/32
162.159.130.0/23
162.159.130.233/32
162.159.130.234/32
162.159.132.0/22
162.159.133.233/32
162.159.133.234/32
162.159.134.233/32
162.159.134.234/32
162.159.135.232/32
162.159.135.233/32
162.159.135.234/32
162.159.136.0/23
162.159.136.232/32
162.159.136.234/32
162.159.137.232/32
162.159.138.0/25
162.159.138.128/26
162.159.138.192/27
162.159.138.224/29
162.159.138.232/32
```

### 4.3 Discord Voice / RTC, IPv4 (`Selector: IP Address` — 32 Entries)

```text
66.22.196.0/22
66.22.200.0/22
66.22.204.0/22
66.22.208.0/22
66.22.212.0/22
66.22.216.0/23
66.22.218.0/23
66.22.220.0/23
66.22.222.0/23
66.22.224.0/23
66.22.226.0/23
66.22.230.0/24
66.22.231.0/24
66.22.232.0/24
66.22.233.0/24
66.22.234.0/24
66.22.235.0/24
66.22.236.0/24
66.22.237.0/24
66.22.238.0/24
66.22.239.0/24
66.22.240.0/24
66.22.241.0/24
66.22.242.0/24
66.22.243.0/24
66.22.243.155/32
66.22.244.0/24
66.22.244.37/32
66.22.245.0/24
66.22.246.0/24
66.22.247.0/24
66.22.248.0/24
```

### 4.4 Google Cloud, IPv4 (`Selector: IP Address` — 11 Entries)

```text
34.0.240.0/20
34.124.0.0/14
35.186.224.24/32
35.186.224.45/32
35.207.192.0/18
35.213.0.0/17
35.213.128.0/18
35.213.192.0/18
35.214.128.0/17
35.215.128.0/18
35.215.192.0/18
```

### 4.5 IPv6 (`Selector: IP Address` — 4 Entries, Optional)

```text
2400:cb00::/32
2405:8100::/32
2606:4700::/32
2a06:98c0::/29
```

### 4.6 Other (`Selector: IP Address` — 1 Entry)

```text
198.244.231.90/32
```

## 5. Related Documents

- Dashboard Configuration: [02-cloudflare-setup.md](02-cloudflare-setup.md)
- WARP Client Setup: [04-warp-setup.md](04-warp-setup.md)
- Automated API Deployment: [06-automation.md](06-automation.md)
