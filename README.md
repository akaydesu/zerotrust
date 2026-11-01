# Cloudflare Zero Trust Üzerinden Discord Trafiğinin Yönlendirilmesi

Bu depo, Discord istemci trafiğinin Cloudflare Zero Trust (WARP) altyapısı üzerinden
yönlendirilmesine ilişkin teknik dokümantasyonu içerir. Dokümanlar; kavramsal çerçeve,
yapılandırma prosedürleri, adres envanteri, doğrulama adımları ve arıza giderme
başlıklarını kapsar.

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-GENEL-001 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| Durum | Yürürlükte |
| Kapsam | Windows 10/11 istemcileri, Cloudflare Zero Trust ücretsiz planı |
| Bakım sorumlusu | Depo sahibi |

## 1. Amaç

Bu doküman seti, Discord uygulamasının ve web istemcisinin erişim engellerinden
etkilenmeden çalışabilmesi için Cloudflare Zero Trust üzerinde kurulması gereken
yapılandırmayı tanımlar. Kurulum; istemci tabanlı Zero Trust erişim modelini esas alır
ve yalnızca Discord trafiğini tünele yönlendirir.

Dokümanlar, yapılandırmayı sıfırdan kuracak bir teknik personelin ihtiyaç duyduğu tüm
adımları içerecek şekilde hazırlanmıştır. Her prosedür, doğrulama adımı ile birlikte
verilmiştir.

## 2. Kapsam

### 2.1 Kapsam içi

- Cloudflare Zero Trust organizasyonunun oluşturulması ve temel ayarları
- Cihaz kayıt (enrollment) politikasının tanımlanması
- WARP istemcisinin kurulumu ve organizasyona kaydı
- Split Tunnel yapılandırmasının "Include" moduna alınması
- Discord adres ve alan adı envanterinin uygulanması
- Tünel protokolünün MASQUE olarak seçilmesi
- Bağlantının doğrulanması ve olası arızaların giderilmesi
- Yapılandırmanın API üzerinden otomatik uygulanması (isteğe bağlı)

### 2.2 Kapsam dışı

- Discord sunucularının veya botlarının barındırılması
- Cloudflare Tunnel (cloudflared) ile hizmet yayımlanması
- Kurumsal kimlik sağlayıcı (IdP) entegrasyonu
- Windows dışı istemci işletim sistemleri
- Ağ tarafında güvenlik duvarı, proxy veya QoS yapılandırması

## 3. Hedef kitle ve ön koşullar

Dokümanlar, ağ ve sistem yönetimi konusunda temel bilgiye sahip teknik personel için
hazırlanmıştır. Uygulama öncesinde aşağıdaki koşullar sağlanmış olmalıdır:

- Cloudflare hesabı ve Zero Trust hizmetine erişim yetkisi
- Windows 10 veya Windows 11 istemci
- Yerel yönetici hakları (istemci kurulumu için)
- Discord uygulamasının kurulu olması (doğrulama adımları için)

## 4. Yöntem özeti

Kurulumda üç bileşen birlikte kullanılır:

1. WARP istemcisi, cihaz üzerinde tüneli sonlandırır ve trafiği yönlendirir.
2. Split Tunnel, hangi hedeflerin tünele gireceğini belirler. "Include" modunda yalnızca
   listede tanımlı hedefler tünelden geçer.
3. MASQUE, tünel trafiğini HTTP/3 (UDP/443) üzerinden taşır.

Trafik akışı aşağıdaki gibidir:

`@
Discord istemcisi / tarayıcı
        |
        |  DNS sorgusu (Cloudflare Gateway DoH)
        v
  WARP istemcisi  -- Split Tunnel: Include
        |
        |  MASQUE / UDP 443
        v
  Cloudflare edge  --->  Discord (api, gateway, cdn, voice)
        ^
        +-- Listede olmayan trafik: doğrudan yerel ağ üzerinden çıkar
`@

Bu yaklaşımın temel avantajı, tüm sistem trafiğinin tünellenmemesidir. Böylece diğer
uygulamaların gecikme ve bant genişliği etkilenmez.

## 5. Doküman seti

| Belge | Dosya | İçerik |
|---|---|---|
| ZT-001 | [01-zero-trust-nedir.md](01-zero-trust-nedir.md) | Zero Trust modeli, bileşenler ve tasarım kararları |
| ZT-002 | [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md) | Panel üzerinden organizasyon, politika ve tünel yapılandırması |
| ZT-003 | [03-ip-ve-dns.md](03-ip-ve-dns.md) | Adres ve alan adı envanteri, sınıflandırma ve bakım |
| ZT-004 | [04-warp-kurulumu.md](04-warp-kurulumu.md) | İstemci kurulumu, kayıt ve bağlantı doğrulaması |
| ZT-005 | [05-sorun-giderme.md](05-sorun-giderme.md) | Belirti, neden ve çözüm eşlemesi |
| ZT-006 | [06-otomasyon.md](06-otomasyon.md) | Yapılandırmanın API ve betik ile uygulanması |

## 6. Uygulama sırası

Kurulum aşağıdaki sırayla yapılmalıdır. Adımlar birbirine bağımlıdır; sıra
değiştirildiğinde cihaz kaydı veya tünel yapılandırması tamamlanmayabilir.

1. Kavramsal çerçevenin gözden geçirilmesi (ZT-001)
2. Cloudflare panelinde organizasyon ve politikaların tanımlanması (ZT-002)
3. Adres envanterinin uygulanması (ZT-003)
4. WARP istemcisinin kurulması ve organizasyona kaydı (ZT-004)
5. Bağlantının doğrulanması (ZT-004, Bölüm 5)
6. Sorun halinde arıza giderme prosedürlerinin uygulanması (ZT-005)

## 7. Sürümleme ve bakım

Dokümanlar Git üzerinde sürümlenir. Her değişiklik, commit mesajında değişen belge
kimliğini belirtecek şekilde kaydedilir. Ayrıntılı değişiklik geçmişi depo commit
kayıtlarında tutulur.

Adres envanteri (ZT-003) dış kaynaklı veriler içerdiğinden düzenli aralıklarla
doğrulanmalıdır. Doğrulama yöntemi ilgili belgede açıklanmıştır.

## 8. Güvenlik ve uyum notları

- Dokümanlarda kimlik bilgisi, API anahtarı veya kuruma özel bilgi bulunmaz.
- API anahtarları yalnızca ilgili prosedür sırasında, geçici olarak kullanılmalıdır.
- Kurulum, cihazın giden trafiğini üçüncü taraf bir ağ üzerinden yönlendirir. Bu durum,
  kurumsal güvenlik politikaları ve yerel mevzuat açısından değerlendirilmelidir.
- Ücretsiz plan, kullanıcı ve cihaz sayısı açısından sınırlıdır; üretim ortamında lisans
  koşulları ayrıca kontrol edilmelidir.

## 9. Kaynakça

- Cloudflare One dokümantasyonu: <https://developers.cloudflare.com/cloudflare-one/>
- Split Tunnels: <https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/>
- WARP istemcisi: <https://one.one.one.one/warp/>
- Adres envanterinin bir bölümü: <https://github.com/sertay1/WarpZeroTrustConfigure>

## 10. Sürüm geçmişi

| Sürüm | Tarih | Açıklama |
|---|---|---|
| 1.0 | 01.11.2026 | Doküman setinin yayımlanması |
