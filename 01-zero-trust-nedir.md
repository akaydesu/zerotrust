# 🧠 Zero Trust Nedir?

**Zero Trust**, "ağın içindesin, o hâlde güvenilirsin" varsayımını reddeden güvenlik modelidir.
Temel kural:

> **"Asla güvenme, her zaman doğrula."**

Kullanıcı, cihaz ve uygulama her erişimde yeniden kontrol edilir. Bu repoda Zero Trust,
**Discord trafiğini engelleri aşacak şekilde tünellemek** için kullanılıyor.

---

## 📌 Temel ilkeler

1. **Kimlik tabanlı erişim** — kullanıcı + cihaz + konum birlikte değerlendirilir
2. **En az yetki** — sadece gereken kaynağa, gereken süre kadar erişim
3. **Sürekli doğrulama** — her bağlantı yeniden denetlenir
4. **Ağ segmentasyonu** — trafik parçalanır, her parça ayrı kuralla yönetilir
5. **Görünürlük** — tüm erişimler kaydedilir ve analiz edilir

---

## 🆚 Klasik VPN ile farkı

| Kriter | Klasik VPN | Zero Trust (ZTNA) |
|---|---|---|
| Erişim yaklaşımı | Ağa giren herkes güvenilir | Her erişim noktasında doğrulama |
| Kaynak erişimi | Tüneldeki herkes her yere | Sadece tanımlı uygulama/kaynak |
| Trafik kapsamı | Genelde **tüm** trafik | **Seçili** uygulama/domain (split tunnel) |
| Ölçeklenebilirlik | Zayıf | Yüksek |
| Gecikme etkisi | Tüm trafik etkilenir | Sadece seçili trafik etkilenir |

Bu repodaki kurulumda **sadece Discord** tünelden geçer; oyun, banka, video gibi
trafik normal hattan çıkar. VPN'in "her şeyi yavaşlatma" sorunu oluşmaz.

---

## 🤖 Discord'da ne işe yarar?

* ISS veya ülke bazlı IP/DNS engellerini aşmak
* Discord'un web + masaüstü + ses trafiğini şifreli tünele almak
* DNS zehirlenmesine karşı sabit IP (`/32`) kullanmak
* Diğer uygulamaları etkilemeden sadece Discord'u yönlendirmek

---

## 🧱 Bu repoda kullanılan model

Burada **Cloudflare Tunnel (`cloudflared`) kullanılmıyor.** Karıştırılan iki ürün var:

| Ürün | Ne yapar | Bu repoda |
|---|---|---|
| **Cloudflare Tunnel** (`cloudflared`) | Sunucudaki bir servisi internete açar (gelen trafik) | ❌ kullanılmıyor |
| **Cloudflare WARP + Zero Trust** | Cihazın **giden** trafiğini Cloudflare üzerinden yönlendirir | ✅ kullanılıyor |

Yani burada bir sunucu yayınlamıyoruz; **kendi bilgisayarımızın Discord trafiğini**
Cloudflare'in ağına sokuyoruz.

```
Discord.exe / tarayıcı
       │
       │ ① DNS: Gateway DoH
       ▼
┌──────────────────┐   Split Tunnel (Include)
│  WARP istemcisi  │   "sadece listedekiler tünele girer"
└──────────────────┘
       │ MASQUE (UDP/443)
       ▼
 Cloudflare edge  ──────►  Discord (api / gateway / cdn / voice)
       ▲
       └── listede olmayan trafik: doğrudan ISS hattı
```

---

## 🧩 Yapı taşları

| Bileşen | Görevi |
|---|---|
| **Zero Trust organizasyonu** | Takım adı, kullanıcı/cihaz kaydı |
| **Access politikası** | Hangi e-postaların cihaz kaydedebileceğini belirler |
| **WARP istemcisi** | Cihazda tüneli açar, trafiği yönlendirir |
| **Split Tunnel** | Hangi trafiğin tünele gireceğini belirler (Include/Exclude) |
| **MASQUE** | Tünel protokolü (HTTP/3, UDP/443) |

---

Devam 👉 [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
