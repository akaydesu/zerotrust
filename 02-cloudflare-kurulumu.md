# 🌐 Cloudflare Zero Trust Kurulumu (adım adım)

Bu bölüm **panelde** yapılacakları anlatır. Süre: ~15 dakika.
Sırayla git; her adımın sonunda "kontrol" satırı var.

> Panel arayüzü zaman zaman değişiyor. Menü adı birebir uyuşmazsa
> **Zero Trust → Settings → WARP Client** çevresine bak; asıl aranan şey
> *Device settings*, *Split Tunnels* ve *Device tunnel protocol*.

---

## 0. Ön koşullar

* Cloudflare hesabı (ücretsiz yeterli)
* Windows 10/11 makine
* Discord **kapalı** olsun (en sonda açacağız)
* Bu repodaki [03-ip-ve-dns.md](03-ip-ve-dns.md) listesi elinin altında olsun

---

## 1. Zero Trust'u etkinleştir

1. <https://dash.cloudflare.com> → hesap oluştur / giriş yap.
2. Sol menüde **Zero Trust**'a gir (hesapta henüz yoksa "Zero Trust" kartından başlat).
3. **Takım adı (team name)** iste: küçük harf, rakam ve tire.
   Örnek: `akaydesu` → adresin `akaydesu.cloudflareaccess.com` olur.
4. Plan seçimi: **Free (50 kullanıcı)**. Ücretsiz planda ücret alınmaz; bazı hesaplarda
   kimlik doğrulama için kart bilgisi istenir.
5. Kurulum sihirbazını bitir (istersen "skip" ile geç).

> ⚠️ Takım adını not et. WARP istemcisine girişte **birebir** bunu yazacaksın.
> Sonradan değiştirirsen cihazların yeniden kaydolması gerekir.

✅ **Kontrol:** `https://<takim-adin>.cloudflareaccess.com` açılıyor mu?

---

## 2. Erişim politikası — "kimler cihaz kaydedebilir?"

Zero Trust'ta varsayılan olarak **hiç kimse** cihaz kaydedemez; önce izin politikası gerekir.

**Yol A — doğrudan (en kısa):** 3. adımdaki ekranda "Create policy" ile anında oluştur.

**Yol B — yeniden kullanılabilir politika:**

1. **Access → Policies → Add a policy**
2. Ayarlar:
   * **Name:** `discord-enroll`
   * **Action:** `Allow`
   * **Include:** `Emails ending in` → `gmail.com` (kendi mail domainini yaz)
   * **Session duration:** `24 hours` (veya `No duration`)
3. **Save**

> Sadece kendi adresine izin vermek istiyorsan `Emails` → `is equal to` →
> `seninadresin@gmail.com` seç. Daha güvenli, ama her yeni cihazda listeyi güncellemen gerekir.

✅ **Kontrol:** Policies listesinde kuralın görünüyor mu?

---

## 3. Cihaz kayıt iznini (enrollment) bağla

1. **Settings → WARP Client** (yeni arayüzde *Team & Resources → Devices* altında da olabilir)
2. **Device enrollment permissions** → **Manage**
3. **Select existing policies** → `discord-enroll` → **Confirm**
   (politika yoksa: **Add a rule** → Allow → Emails ending in → domain)
4. **Save**

> Bu adım atlanırsa WARP istemcisi girişte **"forbidden"** veya
> **"unable to connect"** hatası verir. En sık yapılan hata budur.

✅ **Kontrol:** Enrollment ekranında politika görünüyor mu?

---

## 4. Split Tunnel'ı "Include" moduna al

1. **Settings → WARP Client → Device settings**
2. **Default** profilin yanındaki **Configure**
3. **Split Tunnels** bölümünü bul
4. Mod: `Exclude IPs and domains` → **`Include IPs and domains`** olarak değiştir
5. **Save**

Ne yapar?

| Mod | Anlamı |
|---|---|
| Exclude | Listelenenler tünel **dışında** kalır, geri kalan her şey tünelden gider |
| **Include** | **Sadece listelenenler** tünelden gider, geri kalan her şey normal hattan çıkar |

Discord için doğru olan **Include**: sadece Discord tünellenir; oyun, banka, Netflix
etkilenmez.

---

## 5. Listeyi ekle

1. Aynı sayfada **Split Tunnels → Manage**
2. Her kayıt için:
   * **IP Address** seç → CIDR yaz (`162.159.128.0/19`) → **Save destination**
   * **Domain** seç → alan adı yaz (`discord.com`) → **Save destination**
3. Liste: [03-ip-ve-dns.md](03-ip-ve-dns.md)
   * Acele ediyorsan **A. Hızlı set** (15 kayıt) yeterli
   * Tam kapsam için **B. Tam liste** (164 kayıt)

> İpucu: `*.discord.com` gibi joker kayıtlar alt alan adlarını da kapsar;
> `cdn.discordapp.com` için ayrıca `*.discordapp.com` yeterlidir.

✅ **Kontrol:** Include listesinde kayıtlar görünüyor mu? (en az hızlı set)

---

## 6. Tünel protokolünü MASQUE yap

1. Aynı **Configure** ekranında aşağı in
2. **Device tunnel protocol** → **MASQUE** → **Save**

Neden?

* WireGuard: UDP/2408 — bazı ISS'lerde QoS/DPI ile kısılıyor
* **MASQUE**: HTTP/3, **UDP/443** — normal HTTPS trafiği gibi görünür, daha zor engellenir

> Değişiklik istemci yeniden bağlanınca aktif olur (04. bölümde).

---

## 7. Kontrol listesi

| # | Adım | Durum |
|---|---|---|
| 1 | Takım adı oluşturuldu | ☐ |
| 2 | Allow politikası (e-posta domaini) | ☐ |
| 3 | Enrollment'a politika bağlandı | ☐ |
| 4 | Split Tunnel = **Include** | ☐ |
| 5 | Listeye en az hızlı set girildi | ☐ |
| 6 | Device tunnel protocol = **MASQUE** | ☐ |
| 7 | WARP istemcisi kurulup giriş yapıldı → [04](04-warp-kurulumu.md) | ☐ |

Hepsi tamamsa → [04-warp-kurulumu.md](04-warp-kurulumu.md)

---

## ⚠️ Sık yapılan hatalar

| Hata | Sonuç |
|---|---|
| Enrollment politikası bağlamamak | WARP "forbidden", bağlantı kurulmaz |
| Split Tunnel'ı Exclude'da bırakmak | Discord tünellenmez, engel devam eder |
| Domain'i "IP Address" kutusuna yazmak | Kayıt reddedilir veya boşa çıkar |
| MASQUE'ı seçip **Save**'e basmamak | Protokol değişmez |
| 162.159.128.0/19 yerine tek tek `/32` girmek | Ses/CDN uçları eksik kalır |
| Aynı anda hem include hem exclude doldurmak | Çakışma; biri boşaltılmalı |
