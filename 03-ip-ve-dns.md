# 📡 IP ve DNS Listesi

Split Tunnel **Include** listesine eklenecek hedeflerin tamamı bu dosyada.
İki seçenek var: **hızlı set** (15 kayıt, 5 dakikada biter) veya **tam liste** (164 kayıt).

> Buradaki her satır, Cloudflare panelinde tek bir kayıt (destination) demektir.
> IP'ler **IP Address**, alan adları **Domain** olarak eklenir.

---

## 📊 Özet

| Grup | Kayıt | Ne için |
|---|---:|---|
| Alan adları (domain) | 84 | Web, API, gateway, CDN, güncelleme, davet linkleri |
| Cloudflare anycast IPv4 | 32 | Discord frontend + CDN (162.159.x, 104.18.x) |
| Discord ses / RTC IPv4 | 32 | Ses kanalları, ekran ve video paylaşımı (66.22.x) |
| Google Cloud IPv4 | 11 | Discord'un GCP üzerindeki bileşenleri (34.x, 35.x) |
| IPv6 | 4 | Cloudflare IPv6 aralıkları (geniş kapsam, opsiyonel) |
| Diğer | 1 | Tekil uç nokta |
| **Toplam** | **164** | |

---

## 🚀 A. Hızlı set — 15 kayıt (önerilen başlangıç)

Amaç: tek tek 164 satır girmek yerine, **tüm Discord trafiğini kapsayan** en küçük set.

Mantık:

* `162.159.128.0/19` → `162.159.128.0 – 162.159.159.255` aralığı; listedeki bütün `162.159.x` kayıtlarını (web, API, gateway, CDN) tek satırda kapsar.
* `66.22.192.0/18` → `66.22.192.0 – 66.22.255.255`; Discord ses/RTC bloklarının tamamı bu aralıkta.
* `104.18.0.0/20` + iki `/32` → Discord'un Cloudflare CDN uçları.

### Domainler (10)

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

### IP / CIDR (5)

```text
162.159.128.0/19
66.22.192.0/18
104.18.0.0/20
104.16.51.111/32
104.18.48.115/32
```

> Bu set çoğu kullanıcı için yeterlidir. Ses kanalında kopma yaşarsan tam listeye geç.

---

## 🧩 B. Tam liste — 164 kayıt

### 1) Alan adları (84)

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

### 2) Cloudflare anycast IPv4 (32)

```text
104.16.51.111
104.18.0.0/20
104.18.48.115
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

### 3) Discord ses / RTC IPv4 (32)

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

### 4) Google Cloud IPv4 (11)

```text
34.0.240.0/20
34.124.0.0/14
35.186.224.24
35.186.224.45
35.207.192.0/18
35.213.0.0/17
35.213.128.0/18
35.213.192.0/18
35.214.128.0/17
35.215.128.0/18
35.215.192.0/18
```

### 5) IPv6 (4) — opsiyonel

```text
2400:cb00::/32
2405:8100::/32
2606:4700::/32
2a06:98c0::/29
```

> Bu dört blok Cloudflare'ın **tüm** IPv6 uzayının bir kısmıdır; sadece IPv6 kullanıyorsan
> veya IPv6'da sorun yaşıyorsan ekle. Aksi halde gerek yok.

### 6) Diğer (1)

```text
198.244.231.90/32
```

---

## ❓ Neden bu IP'ler var?

| Kayıt | Açıklama |
|---|---|
| `162.159.128.0/19` | Cloudflare anycast. Discord'un web, API ve gateway trafiği buradan çıkar. DNS zehirlenmesine karşı `/32` pinleri de bu bloğun içinde. |
| `66.22.x` | Discord ses (RTC) sunucuları. Ses kanalı, ekran paylaşımı ve video bu bloklara gider. |
| `104.18.x`, `104.16.x` | Discord CDN / medya. |
| `34.x`, `35.x` | Discord'un Google Cloud üzerinde çalışan bileşenleri. |
| `discord.gg`, `*.discord.gg` | Davet linkleri ve `gateway.discord.gg`. |
| `*.discordapp.com`, `*.discordapp.net` | CDN, medya, ek görseller. |

**Neden hem domain hem IP?** Domain kuralı DNS çözümlemesine bağlıdır; ISP DNS'i
zehirlendiğinde yanlış IP döner. Kritik uçları `/32` olarak eklemek, DNS'e hiç
sormadan trafiği tünele sokar (DNS-independent route).

---

## 🔄 Liste ne zaman güncellenir?

Discord yeni bir ses bölgesi veya CDN ucu açtığında liste eskiler. Kontrol:

```powershell
Resolve-DnsName discord.com -Type A | Select-Object -ExpandProperty IPAddress
Resolve-DnsName gateway.discord.gg -Type A | Select-Object -ExpandProperty IPAddress
```

Dönen IP'ler `162.159.128.0/19` veya `66.22.192.0/18` içinde değilse listeye ekle.

---

## ⚠️ Uyarı

`162.159.128.0/19` ve `104.18.0.0/20` **Cloudflare'a ait genel bloklardır**;
sadece Discord değil, Cloudflare arkasındaki başka siteler de bu aralıklardan çıkar.
Bu yüzden o sitelerin trafiği de tünele girer. Yavaşlama veya beklenmeyen konum
sorunu görürsen bu iki satırı çıkarıp sadece `/32` pinleriyle devam et.
