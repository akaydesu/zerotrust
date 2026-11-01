# 🚑 Sorun Giderme

Önce hızlı teşhis:

`@powershell
warp-cli --accept-tos status
warp-cli --accept-tos settings
warp-cli --accept-tos registration show
`@

---

## Belirti → neden → çözüm

| Belirti | Olası neden | Çözüm |
|---|---|---|
| WARP **"forbidden"** / "unable to connect" | Enrollment politikası bağlı değil | [02/3](02-cloudflare-kurulumu.md) — Device enrollment permissions → politikayı seç |
| WARP bağlanıyor ama Discord açılmıyor | Split Tunnel **Exclude** modunda | Include'a al ([02/4](02-cloudflare-kurulumu.md)) |
| Web açılıyor, **uygulama** açılmıyor | DNS önbelleği / eski oturum | `ipconfig /flushdns`, Discord'u tamamen kapat, WARP'ı yeniden bağla |
| Ses kanalında **"RTC Connecting"** | `66.22.x` yok veya UDP kısıtlı | Listeye ses bloklarını ekle + MASQUE'a geç |
| Ses geliyor ama **mikrofon** gitmiyor | UDP engeli | MASQUE (UDP/443) |
| Sürekli **kopma / handshake** hatası | ISS UDP/2408'i kısıyor | MASQUE'a geç ([02/6](02-cloudflare-kurulumu.md)) |
| Sayfalar **çok yavaş** | `162.159.128.0/19` çok geniş | Bu satırı çıkar, sadece `/32` pinlerini bırak |
| Discord **davet linki** açılmıyor | `discord.gg` listede değil | `discord.gg` + `*.discord.gg` ekle |
| Bir süre sonra **her şey** duruyor | WARP oturumu düşmüş | `warp-cli disconnect` → `connect` |
| Cihaz panelde **görünmüyor** | Kayıt tamamlanmamış | `registration show` → Team/Organization doğru mu? |

---

## 1. Tünel gerçekten Discord'u taşıyor mu?

`@powershell
warp-cli --accept-tos tunnel host list | Select-String discord
warp-cli --accept-tos tunnel ip list   | Select-String '66\.22'
`@

Liste boşsa panelde split tunnel kaydedilmemiş ya da istemci politikayı almamış
demektir. İstemciyi yeniden başlat:

`@powershell
Restart-Service CloudflareWARP
`@

---

## 2. DNS mi, tünel mi?

`@powershell
Resolve-DnsName discord.com -Type A
Resolve-DnsName gateway.discord.gg -Type A
`@

* `0.0.0.0`, `127.0.0.1` veya boş dönüyorsa → DNS tarafı sorunlu
  (WARP kapalı olabilir ya da DoH devre dışı)
* `162.159.x` dönüyorsa → DNS doğru, sorun tünelde/uçta

---

## 3. Port testi

`@powershell
Test-NetConnection gateway.discord.gg -Port 443
Test-NetConnection discord.com -Port 443
`@

`TcpTestSucceeded : False` ise:

* WARP bağlı mı?
* Güvenlik duvarı/antivirüs WARP'ı engelliyor mu?
* Ağ gerçekten internete çıkıyor mu (WARP'ı kapatıp dene)?

---

## 4. Protokol kontrolü

`@powershell
warp-cli --accept-tos settings | Select-String 'protocol'
`@

`WireGuard` görünüyorsa panelde MASQUE seçilmemiş ya da Save'e basılmamıştır.
Panelden değiştirdikten sonra **mutlaka** istemciyi yeniden bağla.

---

## 5. Sıfırdan temiz test

1. `warp-cli --accept-tos disconnect`
2. `ipconfig /flushdns`
3. Discord'u tamamen kapat (tepsiden çık)
4. `warp-cli --accept-tos connect`
5. `warp-cli --accept-tos status` → Connected
6. Discord'u aç

---

## 6. Log ve destek

* WARP logları: `C:\ProgramData\Cloudflare\WARP\logs`
* Panelde cihaz durumu: **Zero Trust → Devices**
* Cloudflare status: <https://www.cloudflarestatus.com>
* Cloudflare One dokümanları: <https://developers.cloudflare.com/cloudflare-one/>

---

## 7. Hâlâ olmuyorsa

| Kontrol | Komut / yer |
|---|---|
| Takım adı doğru mu | `registration show` → Organization |
| Politika e-postanı kapsıyor mu | Panel → Access → Policies |
| Split tunnel include mu | `settings` → "Include mode" |
| Kaç kural var | `tunnel host list` + `tunnel ip list` |
| Cihaz panelde kayıtlı mı | Panel → Devices |

Sorun devam ederse [06-otomasyon.md](06-otomasyon.md) ile listeyi baştan, eksiksiz uygula.
