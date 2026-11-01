<#
.SYNOPSIS
    Discord trafigini Cloudflare Zero Trust (WARP) uzerinden tuneller.

.DESCRIPTION
    Bu script, Cloudflare Zero Trust hesabindaki "Default" cihaz profilinin
    Split Tunnel INCLUDE listesine Discord ICIN gereken tum IP/CIDR ve alan
    adlarini ekler, tunel protokolunu MASQUE yapar ve WARP istemcisini
    yeniden baglar.

    Mevcut listedeki diger kayitlar (premid, fansly vb.) SILINMEZ; yeni
    kurallar mevcutlarin uzerine EKLENIR (idempotent - kac kez calistirirsaniz
    calistirin ayni sonucu verir).

    Cloudflare API'sine yazma izni olan bir token gerekir:
    My Profile > API Tokens > Create Custom Token
    Permissions: Account > Zero Trust > Edit

.PARAMETER ApiToken
    Cloudflare API token. Verilmezse CF_API_TOKEN ortam degiskeni okunur,
    o da yoksa guvenli sekilde (gizli giris) sorulur.

.PARAMETER AccountId
    Cloudflare hesap ID'si. Verilmezse warp-cli kaydindan otomatik bulunur.

.PARAMETER RoutesFile
    Kural dosyasi. Varsayilan: script ile ayni klasordeki discord-routes.txt

.PARAMETER Protocol
    masque (varsayilan) | wireguard | keep

.PARAMETER DryRun
    Hicbir sey degistirmez; mevcut yerel listeyle birlestirip ne
    uygulanacagini gosterir. Token gerektirmez.

.EXAMPLE
    .\Apply-DiscordZeroTrust.ps1 -DryRun

.EXAMPLE
    $env:CF_API_TOKEN = "...."
    .\Apply-DiscordZeroTrust.ps1

.NOTES
    Geri alma: script her calismada mevcut listeyi backup\ icine yazar.
#>
[CmdletBinding()]
param(
    [string]$ApiToken = $env:CF_API_TOKEN,
    [string]$AccountId,
    [string]$RoutesFile,
    [ValidateSet('masque', 'wireguard', 'keep')]
    [string]$Protocol = 'masque',
    [switch]$DryRun,
    [switch]$ClearExclude,
    [switch]$NoReconnect
)

$ErrorActionPreference = 'Stop'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

function Write-Head($t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Info($t) { Write-Host "  [..]   $t" -ForegroundColor Gray }
function Write-Warn($t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
function Write-Err($t)  { Write-Host "  [FAIL] $t" -ForegroundColor Red }
function Write-Kv($k, $v) { Write-Host ("  {0,-22} {1}" -f $k, $v) }

# ---------------------------------------------------------------- WARP CLI ---
$script:WarpCli = $null
function Get-WarpCli {
    if ($script:WarpCli) { return $script:WarpCli }
    $cmd = Get-Command warp-cli -ErrorAction SilentlyContinue
    if ($cmd) { $script:WarpCli = $cmd.Source; return $script:WarpCli }
    $p = Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe'
    if (Test-Path $p) { $script:WarpCli = $p; return $p }
    return $null
}

function Invoke-Warp {
    param([string[]]$WarpArgs)
    $cli = Get-WarpCli
    if (-not $cli) { throw 'warp-cli bulunamadi. Cloudflare WARP kurulu mu?' }
    & $cli --accept-tos @WarpArgs 2>&1
}

function Get-WarpAccountId {
    try {
        $out = (Invoke-Warp @('registration', 'show')) | Out-String
        if ($out -match 'Account ID:\s*([0-9a-fA-F]{32})') { return $Matches[1] }
    } catch { }
    return $null
}

function Get-LocalInclude {
    $items = New-Object System.Collections.ArrayList

    $ipOut = (Invoke-Warp @('tunnel', 'ip', 'list')) | Out-String
    foreach ($line in ($ipOut -split "\r?\n")) {
        if ($line -match '^\s+((?:\d{1,3}(?:\.\d{1,3}){3}|[0-9a-fA-F]{0,4}(?::[0-9a-fA-F]{0,4}){2,})(?:/\d{1,3})?)\s*(?:\((.*)\))?\s*$') {
            $desc = ''
            if ($Matches.Count -gt 2 -and $Matches[2]) { $desc = $Matches[2] }
            [void]$items.Add([pscustomobject]@{ address = $Matches[1]; description = $desc })
        }
    }

    $hostOut = (Invoke-Warp @('tunnel', 'host', 'list')) | Out-String
    foreach ($line in ($hostOut -split "\r?\n")) {
        if ($line -match '^\s+((?:\*\.)?(?:[A-Za-z0-9_-]+\.)+[A-Za-z]{2,})\s*(?:\((.*)\))?\s*$') {
            $desc = ''
            if ($Matches.Count -gt 2 -and $Matches[2]) { $desc = $Matches[2] }
            [void]$items.Add([pscustomobject]@{ host = $Matches[1]; description = $desc })
        }
    }

    return $items
}

# ------------------------------------------------------------------- rules ---
function Read-Routes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Rota dosyasi bulunamadi: $Path" }
    $out = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($raw in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }
        $line = ($line -split '\s+')[0]
        $key = $line.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        if ($line -match '^(?:\d{1,3}(?:\.\d{1,3}){3}|[0-9a-fA-F]{0,4}(?::[0-9a-fA-F]{0,4}){2,})(?:/\d{1,3})?$') {
            if ($line -notmatch '/') {
                if ($line -match ':') { $line = "$line/128" } else { $line = "$line/32" }
            }
            [void]$out.Add([pscustomobject]@{ address = $line; description = 'Discord (Zero Trust)' })
        }
        elseif ($line -match '^(?:\*\.)?(?:[A-Za-z0-9_-]+\.)+[A-Za-z]{2,}$') {
            [void]$out.Add([pscustomobject]@{ host = $line; description = 'Discord (Zero Trust)' })
        }
        else {
            Write-Warn "Gecersiz satir atlandi: $line"
        }
    }
    return $out
}

# --------------------------------------------------------------------- API ---
$script:Headers = $null
$script:ApiBase = $null

function Invoke-Cf {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        $Body,
        [switch]$AsArray
    )
    $params = @{
        Uri        = "$script:ApiBase$Path"
        Method     = $Method
        Headers    = $script:Headers
        TimeoutSec = 40
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        if ($AsArray) {
            $json = ConvertTo-Json -InputObject ([object[]]$Body) -Depth 6 -Compress
        } else {
            $json = ConvertTo-Json -InputObject $Body -Depth 6 -Compress
        }
        $params['Body'] = $json
        $params['ContentType'] = 'application/json'
    }
    try {
        return Invoke-RestMethod @params
    }
    catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        throw "API $Method $Path basarisiz -> $detail"
    }
}

function Get-IncludeList {
    param($Response)
    if ($null -eq $Response) { return @() }
    $res = $Response.result
    if ($null -eq $res) { return @() }
    if ($res -is [System.Array]) { return $res }
    $props = @($res.PSObject.Properties.Name)
    if ($props -contains 'include') { return @($res.include) }
    if ($props -contains 'address' -or $props -contains 'host') { return @($res) }
    return @()
}

function Merge-Lists {
    param($Current, $Wanted)
    $map = New-Object 'System.Collections.Specialized.OrderedDictionary'
    foreach ($e in $Current) {
        $k = $null
        if ($e.address) { $k = ([string]$e.address).ToLowerInvariant() }
        elseif ($e.host) { $k = ([string]$e.host).ToLowerInvariant() }
        if ($k -and -not $map.Contains($k)) { $map[$k] = $e }
    }
    $added = New-Object System.Collections.ArrayList
    foreach ($e in $Wanted) {
        $k = $null
        if ($e.address) { $k = ([string]$e.address).ToLowerInvariant() }
        elseif ($e.host) { $k = ([string]$e.host).ToLowerInvariant() }
        if (-not $k) { continue }
        if (-not $map.Contains($k)) {
            $map[$k] = $e
            [void]$added.Add($e)
        }
    }
    return [pscustomobject]@{
        All   = @($map.Values)
        Added = @($added)
    }
}

function Get-EntryValue($e) {
    if ($e.address) { return [string]$e.address }
    if ($e.host) { return [string]$e.host }
    return '?'
}

# API'den gelen fazladan alanlari (id, created_at vb.) temizler; sadece
# Cloudflare'in kabul ettigi address/host + description kalir.
function ConvertTo-WireEntry($e) {
    $o = [ordered]@{}
    if ($e.address) { $o['address'] = [string]$e.address }
    elseif ($e.host) { $o['host'] = [string]$e.host }
    else { return $null }
    $d = ''
    if ($e.description) { $d = [string]$e.description }
    $o['description'] = $d
    return [pscustomobject]$o
}

# ==================================================================== MAIN ===
Write-Head 'Discord / Cloudflare Zero Trust - Split Tunnel kurulumu'

if (-not $RoutesFile) { $RoutesFile = Join-Path $PSScriptRoot 'discord-routes.txt' }
$wanted = Read-Routes -Path $RoutesFile
Write-Kv 'Rota dosyasi' $RoutesFile
Write-Kv 'Kural sayisi' ("{0} (IP/CIDR + alan adi)" -f $wanted.Count)

$warpCli = Get-WarpCli
if ($warpCli) {
    Write-Kv 'warp-cli' $warpCli
    try {
        $status = (Invoke-Warp @('status')) | Out-String
        Write-Kv 'WARP durumu' (($status -replace "\s+", ' ').Trim())
    } catch { }
} else {
    Write-Warn 'warp-cli bulunamadi - yerel liste okunamayacak.'
}

if (-not $AccountId) { $AccountId = Get-WarpAccountId }
if ($AccountId) { Write-Kv 'Hesap ID' $AccountId } else { Write-Warn 'Hesap ID bulunamadi (-AccountId ile verin).' }

# ---------------------------------------------------------------- DRY RUN ---
if ($DryRun) {
    Write-Head 'DRY RUN - hicbir degisiklik yapilmiyor'
    $current = @()
    if ($warpCli) { $current = Get-LocalInclude }
    $merged = Merge-Lists -Current $current -Wanted $wanted
    Write-Kv 'Mevcut kural' $current.Count
    Write-Kv 'Eklenecek' $merged.Added.Count
    Write-Kv 'Sonuc toplam' $merged.All.Count
    if ($merged.Added.Count -gt 0) {
        Write-Host ''
        Write-Host '  Ilk 10 eklenecek kural:' -ForegroundColor Gray
        $merged.Added | Select-Object -First 10 | ForEach-Object { Write-Host ("    + {0}" -f (Get-EntryValue $_)) }
        if ($merged.Added.Count -gt 10) { Write-Host ("    ... ve {0} tane daha" -f ($merged.Added.Count - 10)) }
    } else {
        Write-Ok 'Liste zaten guncel - eklenecek yeni kural yok.'
    }
    Write-Host ''
    Write-Host '  Gercek uygulama icin:  .\Apply-DiscordZeroTrust.ps1' -ForegroundColor Gray
    return
}

# ------------------------------------------------------------------- token ---
if (-not $ApiToken) {
    Write-Host ''
    Write-Host '  Cloudflare API token gerekli (girdi ekranda gorunmez).' -ForegroundColor Yellow
    Write-Host '  Olusturma: dash.cloudflare.com > My Profile > API Tokens > Create Custom Token' -ForegroundColor DarkGray
    Write-Host '  Izinler : Account > Zero Trust > Edit' -ForegroundColor DarkGray
    $secure = Read-Host '  API Token'
    if (-not $secure) { throw 'Token girilmedi.' }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $ApiToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}
if (-not $AccountId) { throw 'Hesap ID yok. -AccountId <32 karakter> ile calistirin.' }

$script:ApiBase = "https://api.cloudflare.com/client/v4/accounts/$AccountId"
$script:Headers = @{
    Authorization = "Bearer $ApiToken"
    'Content-Type' = 'application/json'
}

# ------------------------------------------------------------------ politika -
Write-Head 'Mevcut politika okunuyor'
$policy = Invoke-Cf -Method GET -Path '/devices/policy'
$pol = $policy.result
if ($pol) {
    Write-Kv 'Profil' ([string]$pol.name)
    Write-Kv 'Tunel protokolu' ([string]$pol.tunnel_protocol)
    Write-Kv 'Mod' ([string]$pol.mode)
} else {
    Write-Warn 'Default cihaz profili okunamadi (result bos).'
}

$excludeResp = $null
try { $excludeResp = Invoke-Cf -Method GET -Path '/devices/policy/exclude' } catch { }
$excludeList = @(Get-IncludeList -Response $excludeResp)
if ($excludeList.Count -gt 0) {
    Write-Warn ("Hesapta {0} adet EXCLUDE kaydi var. Include modu ile cakisabilir." -f $excludeList.Count)
    if (-not $ClearExclude) {
        Write-Warn 'Devam edilirse include uygulanir; exclude listesini temizlemek icin -ClearExclude kullanin.'
    }
}

Write-Head 'Mevcut include listesi cekiliyor'
$incResp = Invoke-Cf -Method GET -Path '/devices/policy/include'
$current = @(Get-IncludeList -Response $incResp)
Write-Kv 'Mevcut kural' $current.Count

$backupDir = Join-Path $PSScriptRoot 'backup'
if (-not (Test-Path -LiteralPath $backupDir)) { [void](New-Item -ItemType Directory -Path $backupDir) }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $backupDir ("include-$stamp.json")
ConvertTo-Json -InputObject ([object[]]$current) -Depth 6 |
    Set-Content -LiteralPath $backupPath -Encoding UTF8
Write-Kv 'Yedek' $backupPath

$merged = Merge-Lists -Current $current -Wanted $wanted
Write-Kv 'Eklenecek' $merged.Added.Count
Write-Kv 'Sonuc toplam' $merged.All.Count
$merged.Added | Select-Object -First 8 | ForEach-Object { Write-Info ("+ {0}" -f (Get-EntryValue $_)) }
if ($merged.Added.Count -gt 8) { Write-Info ("... ve {0} tane daha" -f ($merged.Added.Count - 8)) }

Write-Head 'Include listesi gonderiliyor'
$payload = @($merged.All | ForEach-Object { ConvertTo-WireEntry $_ } | Where-Object { $_ -ne $null })
$putResp = Invoke-Cf -Method PUT -Path '/devices/policy/include' -Body $payload -AsArray
if ($putResp.success -ne $true) {
    throw ("Cloudflare reddetti: " + (($putResp.errors | ForEach-Object { $_.message }) -join ' | '))
}
Write-Ok ("{0} kural yazildi." -f $payload.Count)

if ($ClearExclude -and $excludeList.Count -gt 0) {
    Write-Head 'Exclude listesi temizleniyor'
    [void](Invoke-Cf -Method PUT -Path '/devices/policy/exclude' -Body @() -AsArray)
    Write-Ok 'Exclude temizlendi.'
}

# ----------------------------------------------------------------- protokol ---
if ($Protocol -ne 'keep') {
    Write-Head "Tunel protokolu -> $($Protocol.ToUpper())"
    try {
        $patch = Invoke-Cf -Method PATCH -Path '/devices/policy' -Body @{ tunnel_protocol = $Protocol }
        if ($patch.success -eq $true) {
            Write-Ok "Protokol $Protocol olarak ayarlandi."
        } else {
            Write-Warn ("Protokol degistirilemedi: " + (($patch.errors | ForEach-Object { $_.message }) -join ' | '))
        }
    } catch {
        Write-Warn "Protokol PATCH hatasi: $($_.Exception.Message)"
        Write-Warn 'Dashboard: Zero Trust > Settings > WARP Client > Device settings > Default > Tunnel protocol'
    }
}

# -------------------------------------------------------------- dogrulama ---
Write-Head 'Dogrulama'
Start-Sleep -Seconds 2
$check = Invoke-Cf -Method GET -Path '/devices/policy/include'
$final = @(Get-IncludeList -Response $check)
Write-Kv 'Bulutta kayitli' $final.Count

if (-not $NoReconnect -and $warpCli) {
    Write-Head 'WARP istemcisi yeniden baglaniyor'
    try {
        Invoke-Warp @('disconnect') | Out-Null
        Start-Sleep -Seconds 2
        Invoke-Warp @('connect') | Out-Null
        Start-Sleep -Seconds 4
        $st = (Invoke-Warp @('status')) | Out-String
        Write-Ok (($st -replace "\s+", ' ').Trim())
    } catch {
        Write-Warn "Yeniden baglama hatasi: $($_.Exception.Message)"
    }
}

Write-Head 'Ozet'
Write-Kv 'Toplam kural' $final.Count
Write-Kv 'Yedek dosyasi' $backupPath
Write-Host ''
Write-Host '  Sonraki adim:  .\Verify-DiscordTunnel.ps1' -ForegroundColor Gray
Write-Host '  Discord uygulamasini kapatip yeniden acin, ses kanalinda test edin.' -ForegroundColor Gray
Write-Host ''
