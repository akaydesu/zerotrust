# Cloudflare Zero Trust Yapılandırması

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-002 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| Tahmini süre | 15 dakika |
| İlgili belgeler | ZT-001, ZT-003, ZT-004 |

## 1. Amaç

Bu belge, Cloudflare Zero Trust panelinde yapılması gereken yapılandırmayı adım adım
tanımlar. Prosedür tamamlandığında organizasyon, erişim politikası, cihaz kayıt izni,
split tunnel listesi ve tünel protokolü hazır durumda olur.

## 2. Ön koşullar

- Cloudflare hesabı
- Zero Trust hizmetine erişim yetkisi
- ZT-003 belgesindeki adres envanteri
- Discord uygulaması kapalı olmalıdır (doğrulama sonrası açılacaktır)

## 3. Organizasyonun oluşturulması

### 3.1 Hesap ve hizmet erişimi

1. <https://dash.cloudflare.com> adresine giriş yapın.
2. Sol menüden **Zero Trust** bölümüne geçin.
3. Hizmet ilk kez kullanılıyorsa kurulum sihirbazını başlatın.

### 3.2 Takım adının belirlenmesi

1. Sihirbazda takım adı (team name) istenir.
2. Ad; küçük harf, rakam ve tire içerebilir. Örnek: `ornek-takim`
3. Takım adı, `ornek-takim.cloudflareaccess.com` biçiminde bir alan adı oluşturur.
4. Bu ad, WARP istemcisinin organizasyona kaydı sırasında kullanılacaktır.

Takım adı sonradan değiştirilebilir; ancak bu durumda kayıtlı cihazların yeniden
kaydedilmesi gerekir. Bu nedenle ad, kurulum öncesinde kesinleştirilmelidir.

### 3.3 Plan seçimi

1. Plan listesinden **Free** seçeneğini işaretleyin.
2. Ücretsiz plan, tanımlı kullanıcı ve cihaz sınırına sahiptir.
3. Bazı hesaplarda kimlik doğrulama amacıyla ödeme yöntemi bilgisi istenebilir; ücretsiz
   planda ücret tahsil edilmez.

### 3.4 Doğrulama

Tarayıcıda `https://<takim-adi>.cloudflareaccess.com` adresinin açıldığını doğrulayın.

## 4. Erişim politikasının tanımlanması

Zero Trust, varsayılan olarak hiçbir cihazın kaydedilmesine izin vermez. Cihaz kaydı
öncesinde bir erişim politikası tanımlanmalıdır. Politika iki yolla oluşturulabilir:
cihaz kayıt ekranından doğrudan veya yeniden kullanılabilir politika olarak.

### 4.1 Yeniden kullanılabilir politika oluşturma

1. **Access > Policies** bölümüne gidin.
2. **Add a policy** seçeneğini kullanın.
3. Aşağıdaki alanları doldurun:

| Alan | Değer |
|---|---|
| Name | `discord-enroll` |
| Action | Allow |
| Include | Emails ending in **gmail.com** (kuruma göre değiştirilir) |
| Session duration | 24 hours |

4. Politikayı kaydedin.

Kurumsal kullanımda "Emails ending in" yerine tek tek adres tanımlamak veya bir kimlik
sağlayıcı (IdP) grubu kullanmak daha uygundur. Ücretsiz planda IdP entegrasyonu
sınırlıdır; bu nedenle alan adı bazlı kural yaygın olarak tercih edilir.

### 4.2 Doğrulama

Politika listesinde `discord-enroll` kaydının göründüğünü kontrol edin.

## 5. Cihaz kayıt izninin bağlanması

1. **Settings > WARP Client** bölümüne gidin.
2. **Device enrollment permissions** başlığı altındaki **Manage** düğmesini kullanın.
3. **Select existing policies** seçeneğinden `discord-enroll` politikasını seçin.
4. Değişikliği kaydedin.

Bu adım atlandığında WARP istemcisi organizasyona kaydolamaz ve bağlantı kurulamaz.
Karşılaşılan "forbidden" veya "unable to connect" hatalarının en yaygın nedeni budur.

### 5.1 Doğrulama

Cihaz kayıt ekranında politikaya bağlı bir kuralın listelendiğini doğrulayın.

## 6. Split Tunnel yapılandırması

### 6.1 Modun seçilmesi

1. **Settings > WARP Client > Device settings** bölümüne gidin.
2. **Default** profilin karşısındaki **Configure** düğmesini kullanın.
3. **Split Tunnels** bölümünde modu **Include IPs and domains** olarak değiştirin.
4. Kaydedin.

Mod seçimi, tünelin kapsamını belirler:

| Mod | Davranış |
|---|---|
| Exclude | Listede olmayan tüm trafik tünellenir |
| Include | Yalnızca listede olan trafik tünellenir |

Discord odaklı kurulumda **Include** modu kullanılır. Böylece diğer uygulamaların
trafiği yerel ağ üzerinden çıkmaya devam eder.

### 6.2 Kayıtların eklenmesi

1. Aynı sayfada **Manage** düğmesini kullanın.
2. Her kayıt için hedef türünü seçin:
   - IP adresi veya CIDR bloğu için **IP Address**
   - Alan adı için **Domain**
3. Değeri girin ve **Save destination** ile kaydedin.
4. Envanterdeki tüm kayıtlar eklendikten sonra sayfayı kaydedin.

Envanter ZT-003 belgesinde tanımlıdır. Kayıt sayısı fazla olduğunda panel üzerinden
giriş pratik değildir; ZT-006 belgesinde tanımlanan API yöntemi kullanılabilir.

### 6.3 Doğrulama

Include listesinde en azından hızlı kurulum setinin (ZT-003, Bölüm 4) bulunduğunu
doğrulayın.

## 7. Tünel protokolünün seçilmesi

1. **Configure** ekranında **Device tunnel protocol** alanına ilerleyin.
2. **MASQUE** seçeneğini işaretleyin.
3. Kaydedin.

Protokol değişikliği, istemci yeniden bağlandığında etkinleşir. İstemci tarafındaki
adımlar ZT-004 belgesinde açıklanmıştır.

## 8. Yapılandırmanın doğrulanması

Aşağıdaki tablo, panel tarafındaki yapılandırmanın tamamlanıp tamamlanmadığını
denetlemek için kullanılır.

| No | Denetim | Beklenen durum |
|---|---|---|
| 1 | Takım adı | Tanımlı ve erişilebilir |
| 2 | Erişim politikası | Allow kuralı mevcut |
| 3 | Cihaz kayıt izni | Politikaya bağlı |
| 4 | Split Tunnel modu | Include |
| 5 | Adres envanteri | En az hızlı set yüklü |
| 6 | Tünel protokolü | MASQUE |

## 9. Geri alma

Yapılandırmayı geri almak için aşağıdaki sıra izlenir:

1. **Device settings** ekranında Split Tunnel modunu eski değerine döndürün.
2. Include listesindeki kayıtları kaldırın.
3. Tünel protokolünü önceki değere alın.
4. Cihaz kayıt iznini kaldırın.
5. Gerekirse organizasyonu ve politikayı silin.

Liste değişikliklerini geri almak için ZT-006 belgesindeki yedekleme yöntemi
kullanılabilir.

## 10. Sık karşılaşılan yapılandırma hataları

| Hata | Etki |
|---|---|
| Cihaz kayıt izninin bağlanmaması | WARP organizasyona kaydolamaz |
| Split Tunnel modunun Exclude bırakılması | Discord tünellenmez, engel sürer |
| Alan adının IP alanına girilmesi | Kayıt reddedilir veya işlevsiz kalır |
| Protokolün seçilip kaydedilmemesi | Değişiklik uygulanmaz |
| Include ve Exclude listelerinin birlikte doldurulması | Kural çakışması oluşur |

## 11. İlgili belgeler

- Kavramsal çerçeve: [01-zero-trust-nedir.md](01-zero-trust-nedir.md)
- Adres envanteri: [03-ip-ve-dns.md](03-ip-ve-dns.md)
- İstemci kurulumu: [04-warp-kurulumu.md](04-warp-kurulumu.md)
