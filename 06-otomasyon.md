# Yapılandırmanın API ve PowerShell Betiği ile Otomatik Uygulanması

<div align="right">
  <b>🌐 Dil / Language:</b> 🇹🇷 <b>Türkçe</b> | <a href="en/06-automation.md">🇬🇧 English</a>
</div>

---

| Alan | Değer |
|---|---|
| **Belge kimliği** | ZT-006 |
| **Sürüm** | 2.0 |
| **Yayım tarihi** | 20.11.2026 |
| **İlgili belgeler** | [ZT-002](02-cloudflare-kurulumu.md), [ZT-003](03-ip-ve-dns.md), [ZT-004](04-warp-kurulumu.md) |
| **Ön koşul** | [ZT-002](02-cloudflare-kurulumu.md) Bölüm 3-6 tamamlanmış ve WARP takıma kaydedilmiş olmalı |

## 1. Amaç

Bu belge, 164 kurallık Discord Split Tunnel (`Include`) envanterinin ve **MASQUE** tünel protokolü ayarının Cloudflare API'si üzerinden tek komutla uygulanmasını tanımlar. Bu yöntem, panel üzerinden 164 kaydın tek tek elle girilmesi zahmetini ortadan kaldırır ve yapılandırmanın hatasız, yedekli ve tekrarlanabilir olmasını sağlar.

## 2. Kapsam ve özellikler

- **Mevcut kuralları korur (Idempotent):** Hesabınızdaki Split Tunnel Include listesinde başka sitelere ait kurallarınız varsa **silinmez**; 164 Discord kuralı mevcut listenizin üzerine eklenir. Betiği kaç kez çalıştırırsanız çalıştırın kural tekrarı (duplikasyon) oluşmaz.
- **Otomatik yedekleme:** Betik her çalışmada değişiklik yapmadan önce mevcut bulut listenizi `scripts/backup/include-<tarih>.json` dosyasına yedekler.
- **Protokolü MASQUE yapar:** Cihaz profilinizin tünel protokolünü otomatik olarak `masque` (`HTTP/3 - UDP/443`) olarak günceller ve WARP istemcisini yeniden bağlar.

## 3. Cloudflare API Anahtarı (API Token) Oluşturma

### 3.1 Anahtar oluşturma adımları

1. <https://dash.cloudflare.com> adresinde oturum açın.
2. Sağ üstteki profil simgesinden **My Profile > API Tokens** (veya sol menüden **Manage account > Account API tokens**) bölümüne gidin.
3. **Create Token > Create Custom Token (Get started)** düğmesine tıklayın.
4. Aşağıdaki yetkileri tanımlayın:

| Alan | Değer |
|---|---|
| **Token name** | `zero-trust-discord-setup` |
| **Permissions** | `Account` → `Zero Trust` → `Edit` |
| **Account Resources** | `Include` → Kendi hesabınız |
| **TTL (Geçerlilik süresi)** | Boş bırakılabilir veya sadece bugün için tanımlanabilir |

5. **Continue to summary > Create Token** düğmesine basın ve ekranda yalnızca bir kez gösterilen API anahtarını kopyalayın.

### 3.2 Anahtarın güvenli kullanımı ve iptali

Anahtarı doğrudan ortam değişkenine atayabilir veya betiği çalıştırdığınızda çıkan gizli giriş (`API Token:`) istemine yapıştırabilirsiniz. İşleminiz bittiğinde güvenliğiniz için Cloudflare panelinden ilgili token'ı **Delete** ederek silebilirsiniz.

---

## 4. Betikler ve Dosya Yapısı

| Dosya | İşlev |
|---|---|
| [`scripts/Apply-DiscordZeroTrust.ps1`](scripts/Apply-DiscordZeroTrust.ps1) | 164 kuralı mevcut listeyle birleştirip API'ye yazar, protokolü **MASQUE** yapar ve WARP'ı yeniden bağlar |
| [`scripts/Verify-DiscordTunnel.ps1`](scripts/Verify-DiscordTunnel.ps1) | Servis, takım kaydı, MASQUE protokolü, Split Tunnel kuralları, DNS, TCP 443 ve HTTPS API testlerini yapar |
| [`scripts/discord-routes.txt`](scripts/discord-routes.txt) | Uygulanacak 164 kuralın (84 alan adı + 76 IPv4 + 4 IPv6) tam listesi |

---

## 5. Adım Adım Uygulama Prosedürü

### 5.1 Ön izleme (`-DryRun` — Token gerektirmez)

Hiçbir değişiklik yapmadan, yerel WARP listeniz ile 164 kurallık hedef liste arasındaki farkı görmek için:

```powershell
cd scripts
.\Apply-DiscordZeroTrust.ps1 -DryRun
```

### 5.2 Yapılandırmanın uygulanması

```powershell
.\Apply-DiscordZeroTrust.ps1
```

Betik sizden Cloudflare API Token bilgisini gizli girdi olarak isteyecektir (yazarken ekranda karakter görünmez, yapıştırıp `Enter` tuşuna basın). İsterseniz öncesinde ortam değişkeni olarak da verebilirsiniz:

```powershell
$env:CF_API_TOKEN = "buraya-api-token-yapistirin"
.\Apply-DiscordZeroTrust.ps1
```

### 5.3 Doğrulama (`Verify-DiscordTunnel.ps1`)

```powershell
.\Verify-DiscordTunnel.ps1
```

## 6. Örnek Çalışma Çıktısı

```text
== Discord / Cloudflare Zero Trust - Split Tunnel kurulumu ==
  Rota dosyasi           ...\scripts\discord-routes.txt
  Kural sayisi           164 (IP/CIDR + alan adi)
  WARP durumu            Status update: Connected
  Hesap ID               ••••••••••••••••••••••••••••••••

== Mevcut include listesi cekiliyor ==
  Mevcut kural           29
  Yedek                  ...\scripts\backup\include-20261120-050000.json
  Eklenecek              146
  Sonuc toplam           175

== Include listesi gonderiliyor ==
  [OK]   175 kural yazildi.

== Tunel protokolu -> MASQUE ==
  [OK]   Protokol masque olarak ayarlandi.
```

## 7. Yedekten Geri Alma (Rollback)

Betik her çalışmada mevcut listenizi `scripts/backup/include-<tarih>.json` dosyasına kaydeder. Eski listenize dönmek isterseniz:

```powershell
$acc   = "<32-karakter-account-id>"
$token = "<api-anahtari>"
$h     = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$old   = Get-Content .\scripts\backup\include-20261120-050000.json -Raw
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $old
```

## 8. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Adres envanteri: [03-ip-ve-dns.md](03-ip-ve-dns.md)
- Sorun giderme: [05-sorun-giderme.md](05-sorun-giderme.md)
