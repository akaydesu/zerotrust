# İstemci Kurulumu ve Bağlantı Doğrulaması

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-004 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| Tahmini süre | 10 dakika |
| İlgili belgeler | ZT-002, ZT-003, ZT-005 |

## 1. Amaç

Bu belge, WARP istemcisinin kurulumunu, organizasyona kaydını ve bağlantının
doğrulanmasını tanımlar. Prosedür, ZT-002 belgesindeki panel yapılandırması
tamamlandıktan sonra uygulanır.

## 2. Ön koşullar

- ZT-002 tamamlanmış olmalıdır (organizasyon, politika, split tunnel, protokol).
- İstemcide yerel yönetici hakları bulunmalıdır.
- Cihaz internete erişebiliyor olmalıdır.

## 3. Kurulum

### 3.1 Kurulum dosyasının edinilmesi

1. <https://one.one.one.one/warp/> adresine gidin.
2. Windows için kurulum dosyasını indirin.
3. Dosyanın imzalı ve resmî kaynaktan geldiğini doğrulayın.

### 3.2 Kurulumun yapılması

1. Kurulum dosyasını yönetici olarak çalıştırın.
2. Sihirbazı varsayılan seçeneklerle tamamlayın.
3. Kurulum sonunda `Cloudflare WARP` hizmetinin çalıştığını doğrulayın.

```powershell
Get-Service -Name CloudflareWARP | Select-Object Status, StartType
warp-cli --version
```

Beklenen durum: hizmet `Running`, başlangıç türü `Automatic`.

## 4. Organizasyona kayıt

### 4.1 Arayüz üzerinden kayıt

1. Sistem tepsisindeki WARP simgesine tıklayın.
2. **Ayarlar** bölümüne girin.
3. **Hesap** sekmesinde **Cloudflare Zero Trust ile oturum aç** seçeneğini kullanın.
4. ZT-002 belgesinde belirlenen takım adını girin.
5. Açılan tarayıcı penceresinde kurumsal veya kişisel e-posta adresinizi girin.
6. E-posta ile gönderilen doğrulama kodunu girin.
7. İstemcinin bağlandığını doğrulayın.

### 4.2 Komut satırı üzerinden kayıt

Arayüz kullanılmadan aynı işlem aşağıdaki komutlarla yapılabilir:

```powershell
warp-cli --accept-tos teams-enroll <takim-adi>
warp-cli --accept-tos connect
```

Komut, tarayıcıda kimlik doğrulama penceresi açar. Doğrulama tamamlandığında istemci
otomatik olarak bağlanır.

### 4.3 Kaydın doğrulanması

```powershell
warp-cli --accept-tos registration show
```

Çıktıda `Account type: Team` ve beklenen organizasyon adı görülmelidir. Kayıt
türünün `Team` olmaması, istemcinin organizasyona değil genel WARP hizmetine
kaydedildiğini gösterir.

## 5. Bağlantının doğrulanması

### 5.1 Durum kontrolü

```powershell
warp-cli --accept-tos status
```

Beklenen çıktı: `Connected`. `Disconnected` veya `Unable to connect` durumunda
ZT-005 belgesindeki prosedür uygulanır.

### 5.2 Yapılandırma kontrolü

```powershell
warp-cli --accept-tos settings
```

Aşağıdaki değerler doğrulanır:

| Alan | Beklenen değer |
|---|---|
| WARP tunnel protocol | MASQUE |
| Split tunnel modu | Include mode |
| Include listesi | Discord kayıtlarını içerir |

### 5.3 Tünel kapsamının kontrolü

```powershell
warp-cli --accept-tos tunnel ip list
warp-cli --accept-tos tunnel host list
```

Listelerde Discord'a ait IP blokları ve alan adları görülmelidir. Liste boşsa panel
yapılandırması istemciye ulaşmamıştır; istemci yeniden başlatılır.

## 6. İşlevsel doğrulama

Kurulumun tamamlandığı, aşağıdaki adımlarla doğrulanır:

1. Tarayıcıda `https://discord.com/login` adresini açın.
2. Discord uygulamasını başlatın ve oturum açın.
3. Bir ses kanalına bağlanın ve mikrofon testi yapın.
4. Kanal listesinin, ek görsellerin ve davet bağlantılarının yüklendiğini doğrulayın.

Ek olarak DNS ve port erişimi kontrol edilebilir:

```powershell
Resolve-DnsName discord.com -Type A | Select-Object -ExpandProperty IPAddress
Test-NetConnection gateway.discord.gg -Port 443
```

## 7. Protokolün doğrulanması

```powershell
warp-cli --accept-tos settings | Select-String 'protocol'
```

`WireGuard` değeri görülüyorsa paneldeki protokol ayarı kaydedilmemiş veya istemci
politikayı henüz almamıştır. İstemci yeniden bağlanır:

```powershell
warp-cli --accept-tos disconnect
Start-Sleep -Seconds 2
warp-cli --accept-tos connect
```

## 8. İşletim notları

- İstemci, bilgisayar açılışında otomatik başlatılmalıdır. Bu ayar WARP arayüzündeki
  genel ayarlar bölümünden yapılır.
- İstemci kapalıyken tünel devre dışı kalır ve Discord erişimi etkilenebilir.
- Sürüm güncellemeleri otomatik olarak uygulanır; kurumsal ortamlarda güncelleme
  penceresi ayrıca planlanabilir.
- Uzun süreli oturumlarda bağlantı düşebilir; ZT-005 belgesindeki yeniden başlatma
  prosedürü uygulanır.

## 9. Kayıt silme ve kaldırma

Cihazı organizasyondan çıkarmak için:

```powershell
warp-cli --accept-tos disconnect
warp-cli --accept-tos registration delete
```

Ardından istemci Windows üzerinden kaldırılır. Panelde **Devices** listesinde kalan
kayıtlar varsa ilgili yerden silinir.

## 10. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Arıza giderme: [05-sorun-giderme.md](05-sorun-giderme.md)
