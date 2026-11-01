# Adres ve Alan Adı Envanteri

| Alan | Değer |
|---|---|
| Belge kimliği | ZT-003 |
| Sürüm | 1.0 |
| Yayım tarihi | 01.11.2026 |
| Toplam kayıt | 164 |
| İlgili belgeler | ZT-002, ZT-004, ZT-006 |

## 1. Amaç

Bu belge, Cloudflare Zero Trust split tunnel yapılandırmasında kullanılacak hedeflerin
envanterini tanımlar. Envanter iki düzeyde sunulur: hızlı kurulum için yeterli olan
asgari set ve tüm uç noktaları kapsayan tam envanter.

## 2. Sınıflandırma

| Grup | Kayıt sayısı | Kapsam |
|---|---:|---|
| Alan adları | 84 | Web, API, gateway, CDN, güncelleme ve davet alan adları |
| Cloudflare anycast (IPv4) | 32 | Discord ön yüz ve CDN blokları |
| Discord ses / RTC (IPv4) | 32 | Ses, görüntü ve ekran paylaşımı uç noktaları |
| Google Cloud (IPv4) | 11 | Discord'un Google Cloud üzerindeki bileşenleri |
| IPv6 | 4 | Cloudflare IPv6 blokları (isteğe bağlı) |
| Diğer | 1 | Tekil uç nokta |
| **Toplam** | **164** | |

Kayıtlar panelde iki türde girilir: IP ve CIDR blokları "IP Address", alan adları
"Domain" olarak tanımlanır. Joker kayıtlar (`*.alanadi`) alt alan adlarını kapsar.

## 3. Envanterin kaynağı

Envanter üç kaynaktan derlenmiştir:

1. Discord istemcisinin kullandığı, kamuya açık alan adları.
2. Cloudflare'in yayımladığı anycast blokları.
3. Açık kaynak bir yapılandırma aracının (WarpZeroTrustConfigure) listesi.

Üçüncü kaynak yalnızca veri olarak kullanılmıştır; ilgili yazılım bu kurulumda
çalıştırılmaz. Envanterin güncelliği, Bölüm 7'deki prosedürle periyodik olarak
doğrulanmalıdır.

## 4. Hızlı kurulum seti

Tüm envanterin girilmesi zaman aldığından, çoğu kullanım senaryosu için yeterli olan
asgari set aşağıda tanımlanmıştır. Bu set, geniş bloklar kullanarak tek tek kayıt
girme ihtiyacını ortadan kaldırır.

| Kayıt | Kapsam |
|---|---|
| 162.159.128.0/19 | 162.159.128.0 - 162.159.159.255 aralığı; envanterdeki tüm 162.159.x kayıtlarını kapsar |
| 66.22.192.0/18 | 66.22.192.0 - 66.22.255.255 aralığı; ses/RTC bloklarının tamamını kapsar |
| 104.18.0.0/20 | Cloudflare CDN bloğu |
| 104.16.51.111/32 | CDN uç noktası |
| 104.18.48.115/32 | CDN uç noktası |

### 4.1 Alan adları

```text
discord.com
*.discord.com
discord.gg
*.discord.gg
discordapp.com
*.discordapp.com
discordapp.net
*.discordapp.net
discord.media
*.discord.media
```

### 4.2 IP ve CIDR

```text
162.159.128.0/19
66.22.192.0/18
104.18.0.0/20
104.16.51.111/32
104.18.48.115/32
```

Bu set ile toplam 15 kayıt tanımlanmış olur. Ses kanallarında kopma veya medya
yüklenmesinde sorun görülürse Bölüm 5'teki tam envantere geçilmelidir.

## 5. Tam envanter

### 5.1 Alan adları (84)

```text
*.bigbeans.solutions
*.daveprotocol.com
*.dis.gd
*.discord-activities.com
*.discord.co
*.discord.com
*.discord.design
*.discord.dev
*.discord.fr
*.discord.gg
*.discord.gift
*.discord.gifts
*.discord.media
*.discord.new
*.discord.store
*.discord.tools
*.discordactivities.com
*.discordapp.com
*.discordapp.io
*.discordapp.net
*.discordcdn.com
*.discordmedia.com
*.discordmerch.com
*.discordpartygames.com
*.discordsays.com
*.discordsez.com
*.discordstatus.com
*.discordusercontent.com
*.updates.discord.com
*.watchanimeattheoffice.com
airhorn.solutions
airhornbot.com
bigbeans.solutions
canary.discord.com
cdn.discordapp.com
cdn.discordapp.net
click.discord.com
collector.discord.com
daveprotocol.com
dfr.gg
dis.gd
discord-activities.com
discord-attachments-uploads-prd.storage.googleapis.com
discord.app
discord.co
discord.com
discord.design
discord.dev
discord.fr
discord.gg
discord.gift
discord.gifts
discord.media
discord.new
discord.store
discord.tools
discordactivities.com
discordapp.com
discordapp.io
discordapp.net
discordcdn.com
discordmerch.com
discordpartygames.com
discordsays.com
discordsez.com
discordstatus.com
dl.discordapp.net
fonts.discord.com
gateway-us-east1-b.discord.gg
gateway.discord.gg
gateway.discord.media
i.dis.gd
images-ext-1.discordapp.net
images-ext-2.discordapp.net
media.discordapp.net
ptb.discord.com
push.discord.com
remote-auth-gateway.discord.gg
software-update.discord.com
status.discord.com
support.discord.com
updates.discord.com
versions.discord.com
watchanimeattheoffice.com
```

### 5.2 Cloudflare anycast, IPv4 (32)

```text
104.16.51.111
104.18.0.0/20
104.18.48.115
162.159.128.0/19
162.159.128.0/24
162.159.128.0/25
162.159.128.233/32
162.159.128.234/31
162.159.128.236/30
162.159.128.240/28
162.159.129.0/24
162.159.129.233/32
162.159.130.0/23
162.159.130.233/32
162.159.130.234/32
162.159.132.0/22
162.159.133.233/32
162.159.133.234/32
162.159.134.233/32
162.159.134.234/32
162.159.135.232/32
162.159.135.233/32
162.159.135.234/32
162.159.136.0/23
162.159.136.232/32
162.159.136.234/32
162.159.137.232/32
162.159.138.0/25
162.159.138.128/26
162.159.138.192/27
162.159.138.224/29
162.159.138.232/32
```

### 5.3 Discord ses / RTC, IPv4 (32)

```text
66.22.196.0/22
66.22.200.0/22
66.22.204.0/22
66.22.208.0/22
66.22.212.0/22
66.22.216.0/23
66.22.218.0/23
66.22.220.0/23
66.22.222.0/23
66.22.224.0/23
66.22.226.0/23
66.22.230.0/24
66.22.231.0/24
66.22.232.0/24
66.22.233.0/24
66.22.234.0/24
66.22.235.0/24
66.22.236.0/24
66.22.237.0/24
66.22.238.0/24
66.22.239.0/24
66.22.240.0/24
66.22.241.0/24
66.22.242.0/24
66.22.243.0/24
66.22.243.155/32
66.22.244.0/24
66.22.244.37/32
66.22.245.0/24
66.22.246.0/24
66.22.247.0/24
66.22.248.0/24
```

### 5.4 Google Cloud, IPv4 (11)

```text
34.0.240.0/20
34.124.0.0/14
35.186.224.24
35.186.224.45
35.207.192.0/18
35.213.0.0/17
35.213.128.0/18
35.213.192.0/18
35.214.128.0/17
35.215.128.0/18
35.215.192.0/18
```

### 5.5 IPv6 (4, isteğe bağlı)

```text
2400:cb00::/32
2405:8100::/32
2606:4700::/32
2a06:98c0::/29
```

IPv6 blokları, cihaz ağında IPv6 etkinse ve bağlantı sorunları IPv6 üzerinde
gözleniyorsa eklenmelidir. IPv4 yeterli olduğunda bu kayıtlar atlanabilir.

### 5.6 Diğer (1)

```text
198.244.231.90/32
```

## 6. Adres seçiminin gerekçesi

**Sabit IP kayıtları (/32).** Alan adı kuralları DNS yanıtına bağlıdır. DNS yanıtının
değiştirildiği ağlarda alan adı kuralı yanlış adrese yönlendirme yapabilir. Kritik uç
noktaların sabit IP olarak tanımlanması, çözümleme sonucundan bağımsız olarak trafiğin
tünele girmesini sağlar.

**Geniş anycast blokları.** Discord, Cloudflare anycast ağı üzerinden hizmet verir.
Tek tek IP tanımlamak yerine bloğun tamamının tanımlanması, adres değişikliklerinde
yapılandırmanın geçerliliğini korur.

**Ses blokları.** Ses ve görüntü trafiği, web trafiğinden farklı bloklardan çıkar.
Bu bloklar tanımlanmadığında metin tabanlı özellikler çalışırken ses kanalları
bağlanmayabilir.

## 7. Bakım ve doğrulama

Envanter, Discord altyapısındaki değişikliklere bağlı olarak güncellenmelidir. Önerilen
periyot üç aydır. Doğrulama prosedürü aşağıdaki gibidir:

1. Alan adlarının çözümlemesini kontrol edin:

```powershell
Resolve-DnsName discord.com -Type A | Select-Object -ExpandProperty IPAddress
Resolve-DnsName gateway.discord.gg -Type A | Select-Object -ExpandProperty IPAddress
```

2. Dönen adreslerin 162.159.128.0/19 veya 66.22.192.0/18 blokları içinde olduğunu
   doğrulayın.
3. Blok dışında bir adres döndüğünde ilgili kaydı envantere ekleyin.
4. Değişikliği ZT-002 veya ZT-006 prosedürü ile uygulayın.

## 8. Sınırlamalar

- 162.159.128.0/19 ve 104.18.0.0/20 blokları Cloudflare'in genel bloklarıdır. Bu
  aralıklarda hizmet veren Discord dışındaki siteler de tünele girer.
- Geniş bloklar, tünel üzerindeki trafik hacmini artırır. Ölçülü bir yapılandırma
  gerektiğinde yalnızca /32 kayıtları kullanılabilir.
- Envanter, Discord'un kullanmadığı bazı alan adlarını da içerebilir; bu kayıtlar
  işlevsizdir ancak yapılandırmayı bozmaz.
- Cloudflare panelinde split tunnel listesi için üst sınır bulunmaktadır. Mevcut
  envanter bu sınırın altındadır; ileride eklenecek kayıtlarda sınır göz önünde
  bulundurulmalıdır.

## 9. İlgili belgeler

- Yapılandırma prosedürü: [02-cloudflare-kurulumu.md](02-cloudflare-kurulumu.md)
- Otomasyon: [06-otomasyon.md](06-otomasyon.md)
