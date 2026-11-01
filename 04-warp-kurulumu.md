# 💻 WARP İstemcisi Kurulumu ve Giriş

Panel tarafı bittiyse sıra cihazda. Süre: ~5 dakika.

---

## 1. İndir ve kur

1. <https://one.one.one.one/warp/> → **Download for Windows**
2. `Cloudflare_WARP_Setup.exe` dosyasını çalıştır
3. Kurulum sonrası WARP sistem tepsisinde (sağ alt) görünür

> Kurulum yönetici hakları ister. Kurumsal antivirüs/EDR varsa WARP servisine izin ver.

---

## 2. Zero Trust takımına giriş yap

**Arayüzden:**

1. Tepsideki WARP simgesine tıkla → **Ayarlar (dişli)**
2. **Hesap (Account)** sekmesi
3. **Cloudflare Zero Trust ile oturum aç** / *Login with Cloudflare Zero Trust*
4. Takım adını yaz: `akaydesu` (02. bölümde belirlediğin ad)
5. Tarayıcı açılır → e-posta gir → gelen kodu yaz
6. "Connected" durumuna geçer

**Komut satırından (aynı iş):**

```powershell
warp-cli --accept-tos teams-enroll akaydesu
# tarayıcı açılır, e-posta doğrulaması yapılır
warp-cli --accept-tos connect
```

---

## 3. Bağlantıyı doğrula

```powershell
warp-cli --accept-tos status
# Status update: Connected

warp-cli --accept-tos registration show
# Account type: Team
# Organization: akaydesu

warp-cli --accept-tos settings
# WARP tunnel protocol: MASQUE      ← hedef
# Include mode, with hosts/ips:     ← liste burada görünür
```

Beklenen: `Connected`, `MASQUE` ve include listesinde Discord kayıtları.

---

## 4. Gerçek test

1. Tarayıcıda <https://discord.com/login> aç
2. Discord uygulamasını aç, giriş yap
3. Bir ses kanalına gir, mikrofon testi yap
4. Kanal listesi, ekran görüntüleri, davet linki (`discord.gg/...`) dene

```powershell
# DNS ve TCP hızlı kontrol
Resolve-DnsName discord.com -Type A | Select-Object -ExpandProperty IPAddress
Test-NetConnection gateway.discord.gg -Port 443
```

---

## 5. Protokol gerçekten MASQUE mu?

```powershell
warp-cli --accept-tos settings | Select-String 'protocol|Mode'
```

`WireGuard` yazıyorsa panelde 02/6. adımı tekrar kontrol et ve istemciyi
yeniden başlat:

```powershell
warp-cli --accept-tos disconnect
warp-cli --accept-tos connect
```

---

## 6. Otomatik başlatma

* WARP → Ayarlar → **Genel** → "Bilgisayar açıldığında başlat" açık olsun.
* Discord'un ağ sorunları genelde WARP kapalıyken ortaya çıkar; kapalıysa Discord
  yine engellenir.

---

## 7. Kaldırma / geri alma

```powershell
warp-cli --accept-tos disconnect
warp-cli --accept-tos registration delete   # cihaz kaydını siler
```

Sonra Windows "Uygulamalar"dan Cloudflare WARP'ı kaldır.
Panelde cihaz **Devices** listesinde kalırsa oradan da silebilirsin.

---

Sorun mu var? 👉 [05-sorun-giderme.md](05-sorun-giderme.md)
