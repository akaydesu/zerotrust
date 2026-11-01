# Arıza Tespiti ve Giderme

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-005 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| İlgili belgeler | ZT-002, ZT-004, ZT-006 |

## 1. Amaç

Bu belge, kurulum sonrasında karşılaşılan bağlantı ve erişim sorunlarının
sınıflandırılmasını ve giderilmesini tanımlar. Prosedürler, kök nedeni belirlemeye
yönelik sıralı kontroller içerir.

## 2. İlk teşhis

Sorun bildirildiğinde aşağıdaki üç komut çalıştırılır ve çıktıları kaydedilir:

```powershell
warp-cli --accept-tos status
warp-cli --accept-tos registration show
warp-cli --accept-tos settings
```

Bu çıktılar; bağlantı durumu, organizasyon kaydı ve tünel yapılandırması hakkında
ilk değerlendirmeyi sağlar.

## 3. Belirti ve çözüm eşlemesi

| Belirti | Olası neden | Uygulanacak işlem |
|---|---|---|
| İstemci "forbidden" veya "unable to connect" hatası veriyor | Cihaz kayıt izni tanımlı değil | ZT-002, Bölüm 5 |
| Bağlantı kuruluyor, Discord açılmıyor | Split tunnel Exclude modunda | ZT-002, Bölüm 6.1 |
| Web istemcisi açılıyor, uygulama açılmıyor | DNS önbelleği veya eski oturum | `ipconfig /flushdns`, uygulamayı kapatıp yeniden başlatma |
| Ses kanalı "RTC Connecting" durumunda kalıyor | Ses blokları envanterde yok veya UDP kısıtlı | ZT-003, Bölüm 5.3; protokolü MASQUE yapma |
| Ses geliyor, mikrofon çalışmıyor | Giden UDP kısıtı | Protokolü MASQUE yapma |
| Bağlantı sık kopuyor | UDP/2408 kısıtı | ZT-002, Bölüm 7 |
| Sayfa yüklemesi yavaş | Geniş anycast blokları | ZT-003, Bölüm 8 |
| Davet bağlantıları açılmıyor | `discord.gg` kaydı eksik | ZT-003, Bölüm 5.1 |
| Belirli aralıklarla tüm bağlantı duruyor | İstemci oturumu düşmüş | Bölüm 5, yeniden başlatma |
| Cihaz panelde görünmüyor | Kayıt tamamlanmamış | `registration show` çıktısını kontrol etme |

## 4. Ayrıntılı kontroller

### 4.1 Tünel kapsamı

```powershell
warp-cli --accept-tos tunnel host list
warp-cli --accept-tos tunnel ip list
```

Liste boşsa veya Discord kayıtlarını içermiyorsa panel yapılandırması istemciye
ulaşmamıştır. İstemci hizmeti yeniden başlatılır:

```powershell
Restart-Service -Name CloudflareWARP
```

### 4.2 DNS çözümlemesi

```powershell
Resolve-DnsName discord.com -Type A
Resolve-DnsName gateway.discord.gg -Type A
```

- Sonuç boş veya `0.0.0.0` ise DNS katmanı sorunludur.
- Sonuç 162.159.x aralığında ise çözümleme doğrudur; sorun tünel veya uç noktadadır.

### 4.3 Port erişimi

```powershell
Test-NetConnection gateway.discord.gg -Port 443
Test-NetConnection discord.com -Port 443
```

`TcpTestSucceeded` değeri `False` ise sırasıyla kontrol edilir: istemci bağlı mı,
güvenlik duvarı WARP trafiğini engelliyor mu, ağ erişimi mevcut mu.

### 4.4 Protokol

```powershell
warp-cli --accept-tos settings | Select-String 'protocol'
```

WireGuard görülüyorsa panelde MASQUE seçimi kaydedilmemiş olabilir. Ayar düzeltildikten
sonra istemci yeniden bağlanır.

## 5. Temiz yeniden başlatma

Bağlantı sorunlarının önemli bölümü aşağıdaki sıra ile giderilir:

1. İstemciyi ayırın: `warp-cli --accept-tos disconnect`
2. DNS önbelleğini temizleyin: `ipconfig /flushdns`
3. Discord uygulamasını tamamen kapatın.
4. İstemciyi bağlayın: `warp-cli --accept-tos connect`
5. Durumu doğrulayın: `warp-cli --accept-tos status`
6. Discord uygulamasını yeniden başlatın.

## 6. Kayıtlar ve destek

- İstemci kayıtları: `C:\ProgramData\Cloudflare\WARP\logs`
- Panelde cihaz durumu: Zero Trust > Devices
- Cloudflare hizmet durumu: <https://www.cloudflarestatus.com>
- Ürün dokümantasyonu: <https://developers.cloudflare.com/cloudflare-one/>

Destek talebi oluşturulurken İstemci sürümü, işletim sistemi sürümü, `status` çıktısı
ve sorunun gözlemlediği saat aralığı eklenmelidir.

## 7. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- İstemci kurulumu: [04-warp-kurulumu.md](04-warp-kurulumu.md)
