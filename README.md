# 🛡️ Zero Trust ile Discord Tünelleme

Cloudflare **Zero Trust (WARP)** kullanarak Discord trafiğini engelleri aşacak şekilde
tünelleme rehberi. Sadece Discord tünelden geçer; oyun, banka, video gibi trafik
normal hattan çıkar.

> **Kapsam:** Windows 10/11 · Cloudflare Zero Trust ücretsiz plan · WARP istemcisi
> **Son güncelleme:** Kasım 2025

---

## 📚 İçindekiler

| # | Dosya | Ne anlatıyor | Süre |
|---|---|---|---|
| 01 | [Zero Trust Nedir?](01-zero-trust-nedir.md) | Kavram, VPN farkı, bu repodaki model | 5 dk |
| 02 | [Cloudflare Kurulumu](02-cloudflare-kurulumu.md) | Panelde takım, politika, split tunnel, MASQUE | 15 dk |
| 03 | [IP ve DNS Listesi](03-ip-ve-dns.md) | Hızlı set (15 kayıt) + tam liste (164 kayıt) | — |
| 04 | [WARP Kurulumu](04-warp-kurulumu.md) | İstemci kurulumu, giriş, doğrulama | 5 dk |
| 05 | [Sorun Giderme](05-sorun-giderme.md) | Belirti → neden → çözüm tablosu | — |
| 06 | [Otomasyon](06-otomasyon.md) | API/script ile tek seferde uygulama (opsiyonel) | 10 dk |

---

## ⚡ 5 adımda özet

1. **Zero Trust'u aç** → takım adı belirle (`akaydesu` gibi) → [02](02-cloudflare-kurulumu.md)
2. **Allow politikası** oluştur (e-posta domainin) → cihaz kayıt iznine bağla
3. **Split Tunnel → Include** yap, listeyi ekle → [03](03-ip-ve-dns.md)
4. **Device tunnel protocol → MASQUE**
5. **WARP'ı kur**, takım adıyla giriş yap → [04](04-warp-kurulumu.md)

---

## 🧭 Nasıl çalışır?

`@
Discord.exe / tarayıcı
       │
       │ ① DNS: Cloudflare Gateway DoH
       ▼
┌──────────────────┐    Split Tunnel = Include
│  WARP istemcisi  │    "sadece listedekiler tünele girer"
└──────────────────┘
       │ ② MASQUE (UDP/443, HTTP/3)
       ▼
 Cloudflare edge  ──────►  Discord (api · gateway · cdn · voice)
       ▲
       └── listede olmayan trafik → doğrudan ISS hattı (etkilenmez)
`@

**Neden bu yöntem?**

* Klasik VPN gibi tüm trafiği yavaşlatmaz — sadece Discord tünellenir
* DNS zehirlenmesine karşı kritik uçlar sabit IP (`/32`) olarak pinlenir
* MASQUE, UDP/2408 engelleyen ağlarda da çalışır

---

## ✅ Gereksinimler

* Cloudflare hesabı ([dash.cloudflare.com](https://dash.cloudflare.com))
* Windows 10/11
* [Cloudflare WARP](https://one.one.one.one/warp/) istemcisi
* Discord (web veya masaüstü)

---

## 📂 Depo yapısı

`@
.
├── README.md                    ← bu dosya
├── 01-zero-trust-nedir.md
├── 02-cloudflare-kurulumu.md
├── 03-ip-ve-dns.md              ← IP / domain listesi
├── 04-warp-kurulumu.md
├── 05-sorun-giderme.md
├── 06-otomasyon.md
└── scripts/
    ├── Apply-DiscordZeroTrust.ps1   ← listeyi + MASQUE'i API ile uygular
    ├── Verify-DiscordTunnel.ps1     ← 15 testlik doğrulama
    └── discord-routes.txt           ← 164 kural (script girdisi)
`@

---

## ⚠️ Notlar

* Bu rehber **sunucu yayınlama** değildir; kendi cihazının **giden** trafiğini yönlendirir.
  Cloudflare Tunnel (`cloudflared`) ile karıştırılmamalıdır → [01](01-zero-trust-nedir.md)
* Ücretsiz plan **50 kullanıcı/cihaz** ile sınırlıdır.
* `162.159.128.0/19` ve `104.18.0.0/20` Cloudflare'ın genel bloklarıdır; bu aralıklardaki
  başka siteler de tünele girer. Ayrıntı: [03](03-ip-ve-dns.md)
* Kullanım sorumluluğu sana aittir; bulunduğun ülkenin mevzuatına ve kullandığın
  hizmetlerin şartlarına uy.

---

## 🙏 Kaynak

IP/domain listesinin bir kısmı [sertay1/WarpZeroTrustConfigure](https://github.com/sertay1/WarpZeroTrustConfigure)
projesinden, bir kısmı Cloudflare/Discord'un yayınladığı aralıklardan derlenmiştir.
