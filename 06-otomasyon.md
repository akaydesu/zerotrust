# Yapılandırmanın API ile Uygulanması

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-006 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| İlgili belgeler | ZT-002, ZT-003 |
| Ön koşul | ZT-002, Bölüm 3-5 tamamlanmış olmalı |

## 1. Amaç

Bu belge, split tunnel envanterinin ve tünel protokolü ayarının Cloudflare API'si
üzerinden uygulanmasını tanımlar. Yöntem, panel üzerinden yüz altmış dört kaydın tek tek
girilmesi yerine kullanılır ve yapılandırmanın tekrarlanabilir olmasını sağlar.

## 2. Kapsam ve sınırlar

- İşlem, Cloudflare hesabına yazma yetkisi gerektirir.
- Betikler Windows PowerShell üzerinde çalışır.
- Betikler yalnızca split tunnel listesini ve protokol ayarını değiştirir; organizasyon,
  politika ve cihaz kayıt ayarlarına dokunmaz.
- İşlem idempotenttir: aynı betik birden fazla kez çalıştırıldığında liste çoğalmaz.

## 3. API anahtarı

### 3.1 Anahtar oluşturma

1. <https://dash.cloudflare.com> adresinde oturum açın.
2. Sağ üst menüden **My Profile > API Tokens** bölümüne gidin.
3. **Create Token > Create Custom Token** seçeneğini kullanın.
4. Aşağıdaki yetkileri tanımlayın:

| Alan | Değer |
|---|---|
| Permissions | Account > Zero Trust > Edit |
| Account Resources | Include > ilgili hesap |
| TTL | Boş veya 30 gün |

5. Anahtarı oluşturun. Anahtar yalnızca bir kez görüntülenir.

### 3.2 Anahtarın kullanımı

Anahtar; ortam değişkeni ile veya betiğin gizli giriş istemi üzerinden verilir.
Kaynak kod, doküman veya commit içine yazılmamalıdır.

```powershell
$env:CF_API_TOKEN = "<api-anahtari>"
```

### 3.3 Anahtarın iptali

İşlem tamamlandığında anahtar **Roll** veya **Delete** edilir. Anahtar yalnızca Zero
Trust yetkisi taşıdığından, sızması durumunda etki alanı bu hizmetle sınırlıdır.

## 4. Betikler

| Dosya | İşlev |
|---|---|
| scripts/Apply-DiscordZeroTrust.ps1 | Envanteri ve protokol ayarını uygular |
| scripts/Verify-DiscordTunnel.ps1 | Bağlantı ve yapılandırma doğrulaması yapar |
| scripts/discord-routes.txt | Uygulanacak kural listesi |

Betikler, çalıştırıldıkları dizindeki `discord-routes.txt` dosyasını girdi olarak
kullanır. Farklı bir liste uygulanacaksa `-RoutesFile` parametresi ile yol verilir.

## 5. Uygulama prosedürü

### 5.1 Ön izleme

Hiçbir değişiklik yapılmadan, mevcut liste ile hedef liste arasındaki fark görüntülenir:

```powershell
cd scripts
.\Apply-DiscordZeroTrust.ps1 -DryRun
```

Çıktıda mevcut kural sayısı, eklenecek kural sayısı ve toplam kural sayısı yer alır.
Bu adım, uygulama öncesinde değişikliğin doğrulanması için zorunlu tutulmalıdır.

### 5.2 Uygulama

```powershell
.\Apply-DiscordZeroTrust.ps1
```

Betik, API anahtarını gizli giriş ile ister. Anahtar ortam değişkeninde tanımlıysa
yeniden sorulmaz.

### 5.3 Doğrulama

```powershell
.\Verify-DiscordTunnel.ps1
```

Betik; hizmet durumu, organizasyon kaydı, protokol, split tunnel kapsamı, DNS, port ve
HTTPS kontrollerini yapar ve sonuçları listeler.

## 6. Betiğin işlem sırası

1. `warp-cli` üzerinden hesap kimliği okunur.
2. Mevcut include listesi API üzerinden alınır.
3. Mevcut liste, zaman damgalı bir dosya olarak yedeklenir.
4. Hedef liste ile mevcut liste birleştirilir; mevcut kayıtlar korunur.
5. Birleşik liste `PUT /accounts/{account_id}/devices/policy/include` ile yazılır.
6. Protokol `PATCH /accounts/{account_id}/devices/policy` ile MASQUE yapılır.
7. İstemci yeniden bağlanır ve sonuç doğrulanır.

## 7. Örnek çıktı

```text
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
```

## 8. Manuel API kullanımı

Betik kullanılmadan, aynı işlemler PowerShell üzerinden yapılabilir:

```powershell
$acc   = "<account-id>"
$token = "<api-anahtari>"
$h = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

# Mevcut listenin okunması
Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h

# Protokol ayarı
Invoke-RestMethod -Method Patch -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy" -Headers $h -Body '{"tunnel_protocol":"masque"}'

# Listenin yazılması
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $json
```

`$json` değişkeni, aşağıdaki biçimde bir dizi içermelidir:

```json
[
  { "address": "162.159.128.0/19", "description": "Cloudflare anycast" },
  { "host": "discord.com", "description": "Discord" }
]
```

## 9. Yedekleme ve geri alma

Betik her çalışmada mevcut listeyi `backup/include-<tarih>.json` dosyasına yazar.
Geri alma işlemi, bu dosyanın içeriğinin aynı uç noktaya gönderilmesiyle yapılır:

```powershell
$old = Get-Content .\backup\include-20261101-120000.json -Raw
Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$acc/devices/policy/include" -Headers $h -Body $old
```

`backup` dizini sürüm kontrolüne dahil edilmez.

## 10. Güvenlik gereklilikleri

- API anahtarı en az yetki ilkesine göre oluşturulur; yalnızca Zero Trust yetkisi verilir.
- Anahtar; betik çıktısına, günlük dosyalarına veya komut geçmişine yazılmamalıdır.
- Betikler yalnızca yönetimsel iş istasyonlarında çalıştırılmalıdır.
- Değişiklikler, üretim kullanıcılarını etkilemeden önce pilot bir cihazda doğrulanır.
- İşlem sonrasında anahtar iptal edilir ve yedek dosyaları erişim denetimli bir
  konumda saklanır.

## 11. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Adres envanteri: [03-ip-ve-dns.md](03-ip-ve-dns.md)
