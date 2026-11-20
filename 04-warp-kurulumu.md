# WARP İstemci Kurulumu ve Bağlantı Doğrulaması

<div align="right">
  <b>🌐 Dil / Language:</b> 🇹🇷 <b>Türkçe</b> | <a href="en/04-warp-setup.md">🇬🇧 English</a>
</div>

---

| Alan | Değer |
|---|---|
| **Belge kimliği** | ZT-004 |
| **Sürüm** | 2.0 (Cloudflare One Client / WARP v2026.7+) |
| **Yayım tarihi** | 20.11.2026 |
| **Tahmini süre** | 5 - 10 dakika |
| **İlgili belgeler** | [ZT-002](02-cloudflare-kurulumu.md), [ZT-003](03-ip-ve-dns.md), [ZT-005](05-sorun-giderme.md) |

## 1. Amaç

Bu belge, Cloudflare WARP (Cloudflare One Client `v2026.7+`) masaüstü istemcisinin Windows üzerine kurulumunu, [ZT-002](02-cloudflare-kurulumu.md) belgesinde oluşturduğumuz Zero Trust takımına (organizasyonuna) kaydını ve Discord bağlantısının doğrulanmasını adım adım açıklar.

## 2. Ön koşullar

- [ZT-002](02-cloudflare-kurulumu.md) tamamlanmış olmalıdır (`Team domain`, e-posta erişim politikası, `Device enrollment permissions`, Split Tunnel `Include` modu, `MASQUE` protokolü).
- Bilgisayarda yerel yönetici (Administrator) hakları bulunmalıdır.
- Discord uygulaması kapalı olmalıdır.

---

## 3. WARP İstemcisinin Kurulumu

### 3.1 Kurulum dosyasının indirilmesi

1. <https://one.one.one.one/> adresine veya Cloudflare Zero Trust panelindeki **`Settings > Downloads`** bölümüne gidin.
2. **Windows** için Cloudflare WARP kurulum dosyasını (`Cloudflare_WARP_Release-x64.msi`) indirin.

### 3.2 Kurulumun yapılması ve servis kontrolü

1. İndirdiğiniz `.msi` kurulum dosyasını çalıştırın ve kurulum sihirbazını tamamlayın.
2. Kurulum sonunda PowerShell üzerinden `CloudflareWARP` servisinin çalıştığını ve güncel sürümü (`2026.7+`) doğrulayın:

```powershell
Get-Service -Name CloudflareWARP | Select-Object Status, StartType
warp-cli --version
```

Beklenen durum: `Status: Running`, `StartType: Automatic`, sürüm `warp-cli 2026.7.x`.

---

## 4. Zero Trust Organizasyonuna (Takıma) Kayıt

WARP ilk kurulduğunda standart `1.1.1.1` (tüketici) modunda açılır. Panelde yaptığımız Split Tunnel (yalnızca Discord) ve **MASQUE** protokol ayarlarının devreye girmesi için istemciyi **Zero Trust** takımımıza bağlamamız gerekir.

### 4.1 Arayüz (GUI) üzerinden kayıt

1. Windows sağ alt sistem tepsisindeki (saatin yanındaki) **Cloudflare WARP** simgesine tıklayın.
2. Pencerenin sağ alt köşesindeki **Ayarlar (⚙️ çark)** simgesine tıklayın ve açılan menüden **Tercihler (`Preferences`)** seçeneğine basın.
3. Açılan pencerede üst sekmelerden **Hesap (`Account`)** sekmesine geçin.
4. Sol alt kısımdaki **Cloudflare Zero Trust ile oturum aç (`Login with Cloudflare Zero Trust`)** düğmesine tıklayın.
5. Karşınıza çıkan **"Ekibinizin adını girin (`What is your team name?`)"** ekranına [ZT-002](02-cloudflare-kurulumu.md) Bölüm 3.2'de belirlediğiniz **takım adını** (`.cloudflareaccess.com` olmadan, yalnızca `<takim-adi>` kısmını) yazın ve **İleri / Tamam** düğmesine basın.
6. Varsayılan web tarayıcınızda otomatik olarak `https://<takim-adi>.cloudflareaccess.com` giriş sayfası açılacaktır:
   - [ZT-002](02-cloudflare-kurulumu.md) Bölüm 4.1'de politikaya eklediğiniz **e-posta adresinizi** girin ve **Send me a code** düğmesine basın.
   - E-posta kutunuza gelen 6 haneli tek kullanımlık doğrulama kodunu (PIN) sayfaya girin.
   - Tarayıcıda çıkan **"Cloudflare WARP / Cloudflare One Client adlı uygulamayı aç"** uyarısını onaylayın.
7. Kayıt tamamlandığında WARP penceresi **`Zero Trust`** moduna geçecek ve durum **`Bağlandı (Connected)`** olacaktır.

### 4.2 Komut satırı (CLI) üzerinden hızlı kayıt (Önerilen Alternatif)

Arayüz menülerine girmeden PowerShell üzerinden tek komutla da takım kaydını başlatabilirsiniz:

```powershell
warp-cli --accept-tos teams-enroll <takim-adi>
warp-cli --accept-tos connect
```

Komut çalıştırıldığında tarayıcıda doğrulama sayfası açılır; e-posta kodunu girdiğiniz anda istemci otomatik olarak bağlanır.

---

## 5. Bağlantının ve Protokolün Doğrulanması

### 5.1 Otomatik doğrulama betiği

Depodaki doğrulama betiğini çalıştırarak servis, takım kaydı, tünel protokolü, Split Tunnel kuralları, DNS, TCP 443 ve HTTPS API erişimini tek seferde test edin:

```powershell
.\scripts\Verify-DiscordTunnel.ps1
```

### 5.2 Manuel CLI kontrolleri (`warp-cli`)

1. **Kayıt kontrolü (`Account type: Team`):**
   ```powershell
   warp-cli --accept-tos registration show
   ```
   Beklenen çıktı:
   ```text
   Account type: Team
   Organization: <takim-adi>
   ```

2. **Bağlantı ve Ağ durumu:**
   ```powershell
   warp-cli --accept-tos status
   ```
   Beklenen çıktı:
   ```text
   Status update: Connected
   Network: healthy
   ```

3. **Protokol (MASQUE & Post-Quantum) ve Split Tunnel kontrolü:**
   ```powershell
   warp-cli --accept-tos settings
   ```
   Çıktıda aşağıdaki alanları kontrol edin:
   - `Mode: WarpWithDnsOverHttps` (Hem trafik tünelleme hem şifreli DoH DNS aktif)
   - `WARP tunnel protocol: MASQUE` (HTTP/3 `UDP/443` protokolü aktif; eğer `WireGuard` görünüyorsa panelden `MASQUE` seçip `Apply-DiscordZeroTrust.ps1` çalıştırarak güncelleyebilirsiniz)
   - `Post-quantum support for MASQUE: Enabled (downgrades allowed)` (Kuantum sonrası şifreleme desteği aktif)
   - `Include mode, with hosts/ips:` altında Discord alan adları (`discord.com`, `*.discord.gg`, `gateway.discord.gg` vb.) ve IP blokları (`162.159.x.x`, `66.22.x.x`) listelenmelidir.

4. **Tünel rota listesini ayrıntılı görüntüleme:**
   ```powershell
   warp-cli --accept-tos tunnel ip list
   warp-cli --accept-tos tunnel host list
   ```

---

## 6. İşlevsel Doğrulama (Discord Testi)

1. Tarayıcıda `https://discord.com/app` adresini açarak web erişimini kontrol edin.
2. **Discord masaüstü uygulamasını** başlatın.
3. Bir ses kanalına bağlanın, **`Ses Bağlandı (Voice Connected / RTC Connected)`** durumunu ve gecikme (ping) değerini kontrol edin.
4. Resimlerin, sunucu simgelerinin ve `discord.gg` davet bağlantılarının sorunsuz yüklendiğini doğrulayın.

## 7. Kayıt Silme ve Normal Mod'a Dönme

Cihazı Zero Trust organizasyonundan çıkarmak isterseniz:

```powershell
warp-cli --accept-tos disconnect
warp-cli --accept-tos registration delete
```

## 8. İlgili belgeler

- Panel yapılandırması: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Sorun giderme rehberi: [05-sorun-giderme.md](05-sorun-giderme.md)
- Otomatik API betiği: [06-otomasyon.md](06-otomasyon.md)
