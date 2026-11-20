# Arıza Tespiti ve Sorun Giderme

<div align="right">
  <b>🌐 Dil / Language:</b> 🇹🇷 <b>Türkçe</b> | <a href="en/05-troubleshooting.md">🇬🇧 English</a>
</div>

---

| Alan | Değer |
|---|---|
| **Belge kimliği** | ZT-005 |
| **Sürüm** | 2.0 (Cloudflare One & WARP v2026.7+) |
| **Yayım tarihi** | 20.11.2026 |
| **İlgili belgeler** | [ZT-002](02-cloudflare-kurulumu.md), [ZT-004](04-warp-kurulumu.md), [ZT-006](06-otomasyon.md) |

## 1. Amaç

Bu belge, kurulum sonrasında karşılaşılan bağlantı, protokol (WireGuard vs MASQUE) ve Discord ses/WebRTC (`RTC Connecting`) sorunlarının sınıflandırılmasını ve giderilmesini tanımlar.

## 2. İlk teşhis

Sorun bildirildiğinde aşağıdaki üç komut PowerShell üzerinde çalıştırılır:

```powershell
warp-cli --accept-tos status
warp-cli --accept-tos registration show
warp-cli --accept-tos settings
```

Veya tüm kontrolleri otomatik yapan doğrulama betiği çalıştırılır:

```powershell
.\scripts\Verify-DiscordTunnel.ps1
```

## 3. Belirti, Kök Neden ve Çözüm Eşlemesi

| Belirti | Olası Kök Neden | Uygulanacak Çözüm |
|---|---|---|
| İstemci girişte **"Forbidden"** veya **"Unable to connect"** hatası veriyor | Cihaz kayıt izni (`Device enrollment permissions`) tanımlı değil veya girdiğiniz e-posta politikada yok | [ZT-002](02-cloudflare-kurulumu.md) Bölüm 4 ve Bölüm 5: `Team & Resources > Devices > Management` altında politikanızı bağlayın |
| WARP `Connected` görünüyor ama Discord hiç açılmıyor | Split Tunnel `Exclude` modunda kalmış veya Discord rotaları henüz istemciye senkronize olmamış | [ZT-002](02-cloudflare-kurulumu.md) Bölüm 6.3: Modu `Include IPs and domains` yapın; `warp-cli disconnect` ve `warp-cli connect` yapın |
| Web tarayıcıdan Discord açılıyor ama masaüstü uygulaması `"Update Failed"` / `"Checking for updates"` döngüsünde kalıyor | Windows DNS önbelleğinde eski/engelli IP kalmış veya `updates.discord.com` listede eksik | `ipconfig /flushdns` komutunu çalıştırın, Discord'u Görev Yöneticisi'nden tamamen kapatıp yeniden açın |
| Ses kanalı **"RTC Connecting"** durumunda takılı kalıyor veya ses gelmiyor | Tünel protokolü `WireGuard` (`UDP/2408`) kalmış ve İSS tarafından daraltılıyor **veya** `66.22.192.0/18` ses IP blokları listede yok | 1. [ZT-002](02-cloudflare-kurulumu.md) Bölüm 6.2'den protokolü **`MASQUE (Recommended)`** yapın.<br/>2. [ZT-003](03-ip-ve-dns.md) Bölüm 5.3'teki `66.22.x.x` ses bloklarını ekleyin. |
| Ses geliyor ancak mikrofonunuz karşıya gitmiyor | Giden UDP paketleri WireGuard portunda düşürülüyor | Tünel protokolünü **MASQUE** (`HTTP/3 - UDP/443`) olarak değiştirin |
| Çevrimiçi oyunlarda ping yükseldi | Split Tunnel modu `Exclude` bırakılmış (tüm bilgisayar trafiği tünelleniyor) | Split Tunnel modunu **`Include IPs and domains`** yapın; böylece sadece Discord tünele girer |
| `discord.gg` davet bağlantıları veya özel emojiler/resimler yüklenmiyor | `discord.gg`, `*.discordapp.net` veya `*.discord.media` kayıtları eksik | [ZT-006](06-otomasyon.md) `Apply-DiscordZeroTrust.ps1` betiği ile 164 kuralın tamamını uygulayın |
| Cihaz Cloudflare panelinde görünmüyor | WARP tüketici (`1.1.1.1`) modunda kalmış, takım kaydı tamamlanmamış | `warp-cli registration show` çıktısında `Account type: Team` olduğundan emin olun ([ZT-004](04-warp-kurulumu.md) Bölüm 4) |

## 4. Ayrıntılı Kontroller

### 4.1 Tünel kapsamı kontrolü

```powershell
warp-cli --accept-tos tunnel host list
warp-cli --accept-tos tunnel ip list
```

Liste boşsa veya Discord kayıtlarını içermiyorsa panel yapılandırması istemciye ulaşmamıştır. İstemci servisini yeniden başlatın:

```powershell
Restart-Service -Name CloudflareWARP
```

### 4.2 DNS çözümlemesi kontrolü

```powershell
Resolve-DnsName discord.com -Type A
Resolve-DnsName gateway.discord.gg -Type A
```

- Sonuç boş, `0.0.0.0` veya `127.0.0.1` ise DNS katmanı engellenmektedir (`Mode: WarpWithDnsOverHttps` olduğunu kontrol edin).
- Sonuç `162.159.128.x` - `162.159.138.x` aralığında ise DNS çözümlemesi sağlıklıdır.

### 4.3 TCP 443 ve Gateway erişim kontrolü

```powershell
Test-NetConnection gateway.discord.gg -Port 443
Test-NetConnection discord.com -Port 443
```

`TcpTestSucceeded : True` dönmelidir.

### 4.4 Protokol kontrolü (MASQUE vs WireGuard)

```powershell
warp-cli --accept-tos settings | Select-String 'protocol|MASQUE'
```

Çıktıda `WARP tunnel protocol: WireGuard` görülüyorsa İSS UDP kısıtlamalarına takılabilirsiniz. Panelde (`Devices > Device profiles > Default > Edit profile settings`) veya `Apply-DiscordZeroTrust.ps1 -Protocol masque` komutuyla protokolü **MASQUE** yapıp istemciyi yeniden bağlayın:

```powershell
warp-cli --accept-tos disconnect
Start-Sleep -Seconds 2
warp-cli --accept-tos connect
```

## 5. Temiz Yeniden Başlatma Prosedürü

Bağlantı sorunlarının büyük bölümü aşağıdaki 6 adımlı temiz yeniden başlatma sırası ile giderilir:

1. İstemci bağlantısını kesin: `warp-cli --accept-tos disconnect`
2. Windows DNS önbelleğini temizleyin: `ipconfig /flushdns`
3. Discord uygulamasını sistem tepsisinden (sağ alt) tamamen kapatın (`Stop-Process -Name Discord -Force -ErrorAction SilentlyContinue`).
4. İstemciyi yeniden bağlayın: `warp-cli --accept-tos connect`
5. Durumu doğrulayın: `warp-cli --accept-tos status` (`Connected`)
6. Discord uygulamasını yeniden başlatın.

## 6. Kayıtlar ve Destek

- İstemci günlük dosyaları: `C:\ProgramData\Cloudflare\WARP\logs`
- Panelde cihaz durumu: `Zero Trust > Team & Resources > Devices > Your devices`
- Cloudflare hizmet durumu: <https://www.cloudflarestatus.com>

## 7. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- İstemci kurulumu: [04-warp-kurulumu.md](04-warp-kurulumu.md)
- Otomasyon betikleri: [06-otomasyon.md](06-otomasyon.md)
