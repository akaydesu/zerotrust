# ⚙️ Otomasyon — API ile tek seferde uygulama

Panelde 164 kaydı tek tek girmek istemiyorsan bu bölüm. İsteğe bağlıdır;
manuele göre 10 dakika yerine ~30 saniye sürer.

> ⚠️ Bu script **senin makinende** çalışır ve **senin** Cloudflare hesabına yazar.
> Token gerekir. Token'ı kimseyle paylaşma, repoya koyma.

---

## 1. API token oluştur

1. <https://dash.cloudflare.com> → sağ üst profil → **My Profile → API Tokens**
2. **Create Token → Create Custom Token**
3. Ayarlar:
   * **Permissions:** `Account` → `Zero Trust` → **Edit**
   * **Account Resources:** Include → kendi hesabın
   * **TTL:** boş (veya 1 ay)
4. **Continue → Create token** → token **bir kez** gösterilir, kopyala

---

## 2. Script'i çalıştır

`@powershell
cd scripts

# 1) Hiçbir şey değiştirmeden farkı gör
.\Apply-DiscordZeroTrust.ps1 -DryRun

# 2) Uygula (token'ı gizli sorar)
.\Apply-DiscordZeroTrust.ps1

# 3) Doğrula
.\Verify-DiscordTunnel.ps1
`@

Token'ı ortam değişkeniyle de verebilirsin:

`@powershell
$env:CF_API_TOKEN = "...."
.\Apply-DiscordZeroTrust.ps1
`@

---

## 3. Script ne yapıyor?

1. `warp-cli`'dan **hesap ID**'sini bulur
2. Mevcut include listesini API'den çeker
3. `backup/include-<tarih>.json` olarak **yedekler**
4. Listeyi **birleştirir** — mevcut kayıtlar silinmez, yeni Discord kuralları eklenir
5. `PUT /accounts/{id}/devices/policy/include` ile yazar
6. `PATCH /accounts/{id}/devices/policy` → `{"tunnel_protocol":"masque"}`
7. WARP'ı disconnect/connect eder, sonucu doğrular

Kaç kez çalıştırırsan çalıştır aynı sonucu verir (idempotent).

---

## 4. Örnek çıktı

`@text
== Discord / Cloudflare Zero Trust - Split Tunnel kurulumu ==
  Rota dosyasi           ...\scripts\discord-routes.txt
  Kural sayisi           164
  Hesap ID               81758aea...
  Mevcut kural           25
  Eklenecek              139
  Sonuc toplam           164
== Include listesi gonderiliyor ==
  [OK]   164 kural yazildi.
== Tunel protokolu -> MASQUE ==
  [OK]   Protokol masque olarak ayarlandi.
`@

---

## 5. Elle (PowerShell) yapmak istersen

`@powershell
$acc   = "<account-id>"
$token = "<api-token>"
$h = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

# mevcut listeyi gör
Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h

# protokolü MASQUE yap
Invoke-RestMethod -Method Patch -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy" -Headers $h -Body '{"tunnel_protocol":"masque"}'

# listeyi yaz (gövde: [{"address":"162.159.128.0/19"},{"host":"discord.com"}, ...])
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $json
`@

---

## 6. Geri alma

`backup/` içindeki JSON, uygulama **öncesi** listeyi tutar. Dönmek için:

`@powershell
$old = Get-Content .\backup\include-20251101-184500.json -Raw
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $old
`@

---

## 7. Güvenlik

* Token yalnızca **Zero Trust: Edit** yetkisi taşır; başka hesap kaynaklarına erişemez
* Script token'ı **loglamaz**, dosyaya yazmaz, ekrana basmaz
* İş bitince token'ı **Roll** veya **Delete** et
* `backup/` klasörünü repoya **commit etme** (`.gitignore` içinde)
