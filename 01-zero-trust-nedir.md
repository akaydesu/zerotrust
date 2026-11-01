# Zero Trust Modeli ve Kurulum Mimarisi

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-001 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| İlgili belgeler | ZT-002, ZT-003, ZT-004 |

## 1. Amaç

Bu belge, kurulumun dayandığı Zero Trust modelini, kullanılan Cloudflare bileşenlerini
ve tasarım kararlarının gerekçelerini açıklar. Yapılandırma adımlarına geçmeden önce
okunması önerilir; zira izleyen belgelerdeki seçimler buradaki model üzerine kuruludur.

## 2. Zero Trust modeli

### 2.1 Tanım

Zero Trust, bir ağın içinde bulunmanın güven için yeterli sayılmadığı güvenlik
yaklaşımıdır. Geleneksel çevre güvenliği modellerinde ağ sınırı güvenilir kabul edilir
ve sınırın içindeki trafik büyük ölçüde denetlenmez. Zero Trust bu varsayımı ortadan
kaldırır: her erişim isteği, kaynağına ve hedefine bakılmaksızın kimlik, cihaz durumu
ve politika koşullarına göre yeniden değerlendirilir.

### 2.2 Temel ilkeler

1. **Kimlik tabanlı erişim.** Erişim kararı; kullanıcı kimliği, cihaz kimliği ve
   bağlantı bağlamı üzerinden verilir.
2. **En az yetki.** Kullanıcı ve cihaz, yalnızca tanımlı kaynaklara ve tanımlı süre
   boyunca erişir.
3. **Sürekli doğrulama.** Erişim, oturum başında bir kez verilen bir izin değildir;
   oturum boyunca koşullar yeniden değerlendirilir.
4. **Ağ segmentasyonu.** Trafik, uygulama ve hedef bazında ayrıştırılır; her parça
   ayrı politika ile yönetilir.
5. **Görünürlük.** Tüm erişim kararları kayıt altına alınır ve denetlenebilir.

Bu kurulumda ilkelerden özellikle ikincisi ve dördüncüsü belirleyicidir: cihazın tüm
trafiği değil, yalnızca Discord'a ait hedefler tünele alınır.

## 3. ZTNA ve geleneksel VPN

| Ölçüt | Geleneksel VPN | Zero Trust (ZTNA) |
|---|---|---|
| Erişim kararı | Ağa bağlanan herkes güvenilir kabul edilir | Her erişim isteği ayrıca değerlendirilir |
| Kaynak kapsamı | Tünel üzerinden tüm ağa erişim | Yalnızca tanımlı uygulama ve hedefler |
| Trafik kapsamı | Genellikle tüm trafik tünellenir | Seçili hedefler tünellenir (split tunnel) |
| Gecikme etkisi | Tüm uygulamalar etkilenir | Yalnızca tünellenen trafik etkilenir |
| Ölçeklenebilirlik | Merkezi toplama noktasına bağımlıdır | Dağıtık kenar ağı üzerinden ölçeklenir |

Bu kurulumda VPN benzeri bir tüm-trafik yönlendirmesi kullanılmaz. Amaç, Discord
trafiğini tünele alırken diğer uygulamaların yerel ağ üzerinden çıkmasını sürdürmektir.
Bu nedenle "split tunnel" yapılandırması kurulumun merkezinde yer alır.

## 4. Kullanılan Cloudflare bileşenleri

| Bileşen | İşlev | Bu kurulumdaki rolü |
|---|---|---|
| Zero Trust organizasyonu | Kullanıcı, cihaz ve politika yönetimi | Cihaz kaydının yapıldığı yapı |
| Access politikası | Kaynak ve cihaz erişim kuralları | Hangi e-posta adreslerinin cihaz kaydedebileceğini belirler |
| WARP istemcisi | Cihazda tünel sonlandırma | Tüneli kurar ve trafiği yönlendirir |
| Gateway (DNS) | DNS çözümleme ve filtreleme | Discord alan adlarının çözümlenmesi |
| Split Tunnel | Tünel kapsamı | Yalnızca Discord hedeflerinin tünellenmesi |
| MASQUE | Tünel taşıma protokolü | HTTP/3 üzerinden UDP/443 taşıma |

WARP istemcisi, cihaz üzerinde bir sanal ağ arayüzü oluşturur ve işletim sisteminin
yönlendirme tablosunu bu arayüz lehine değiştirir. Hangi hedeflerin bu arayüze
yönlendirileceği, Split Tunnel listesi ile belirlenir.

## 5. Cloudflare Tunnel ile farkı

Cloudflare'in iki farklı ürünü sıkça karıştırılmaktadır. Bu kurulumda kullanılan ürün
WARP'tır; Cloudflare Tunnel (cloudflared) kullanılmaz.

| Ürün | Trafik yönü | Kullanım amacı |
|---|---|---|
| Cloudflare Tunnel (cloudflared) | Gelen (inbound) | Sunucuda çalışan bir hizmeti internete açar |
| WARP + Zero Trust | Giden (outbound) | Cihazın trafiğini Cloudflare üzerinden yönlendirir |

Bu nedenle dokümanlarda "tünelleme" ifadesi, cihazın giden trafiğinin yönlendirilmesi
anlamında kullanılmaktadır. Sunucu tarafında bir hizmet yayımlanmaz.

## 6. Trafik akışı

`@
1. Uygulama, hedef alan adı için DNS sorgusu üretir.
2. Sorgu, WARP istemcisi tarafından Cloudflare Gateway'e (DoH) iletilir.
3. Dönen adres, Split Tunnel listesi ile karşılaştırılır.
4. Hedef listede ise bağlantı WARP tüneli üzerinden kurulur.
5. Hedef listede değilse bağlantı yerel ağ üzerinden doğrudan kurulur.
`@

Tünel üzerinden taşınan trafik, MASQUE protokolü kullanıldığında UDP/443 üzerinde
HTTP/3 oturumu içinde iletilir. Bu tercih, UDP/2408 (WireGuard) trafiğinin kısıtlandığı
ağlarda bağlantı sürekliliği sağlar.

## 7. Tasarım kararları

### 7.1 Split Tunnel modunun "Include" seçilmesi

"Include" modunda yalnızca listede tanımlı hedefler tünele girer. "Exclude" modunda ise
liste dışındaki tüm trafik tünellenir. Discord odaklı bir kurulumda "Include" modu
tercih edilir; çünkü diğer uygulamaların trafiği etkilenmez ve tünel üzerindeki yük
asgari düzeyde kalır.

### 7.2 Alan adı ve IP'nin birlikte kullanılması

Alan adı kuralları DNS çözümlemesine bağlıdır. DNS yanıtının değiştirildiği veya
engellendiği durumlarda alan adı kuralı tek başına yeterli olmaz. Bu nedenle kritik uç
noktalar, sabit IP adresi (/32) olarak da tanımlanır. Bu kayıtlar DNS sorgusundan
bağımsız olarak tünele yönlendirilir.

### 7.3 MASQUE protokolünün seçilmesi

WireGuard, UDP/2408 üzerinde çalışır ve bazı ağlarda bu port aralığı kısıtlanır.
MASQUE, HTTP/3 kullanarak trafiği UDP/443 üzerinden taşır. Bu port, standart HTTPS
trafiği ile aynı olduğundan kısıtlama olasılığı daha düşüktür.

## 8. Sınırlamalar

- Kurulum, cihazın giden trafiğini Cloudflare ağı üzerinden yönlendirir; trafik
  Cloudflare'in kabul ettiği bölgesel uç noktalardan çıkar.
- Adres envanterinde yer alan geniş Cloudflare blokları, Discord dışındaki bazı
  hizmetlerin de tünele girmesine neden olabilir. Bu durum ZT-003'te ayrıca ele
  alınmıştır.
- Ücretsiz plan, kullanıcı ve cihaz sayısı ile sınırlıdır.
- Kurulum, yerel ağ politikalarını (proxy, güvenlik duvarı) değiştirmez; bu katmanlarda
  ek kısıtlama varsa bağlantı yine etkilenebilir.

## 9. İlgili belgeler

- Kurulum prosedürü: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Adres envanteri: [03-ip-ve-dns.md](03-ip-ve-dns.md)
- İstemci kurulumu: [04-warp-kurulumu.md](04-warp-kurulumu.md)
