<#
.SYNOPSIS
    Discord'un Cloudflare Zero Trust tuneli uzerinden gercekten aktigini dogrular.

.DESCRIPTION
    Sirasiyla: WARP durumu, takim kaydi, tunel protokolu, split tunnel
    listesi, DNS, TCP 443 ve HTTPS testlerini yapar; sonunda PASS/FAIL ozeti
    basar. Hicbir yapilandirma degistirmez.

.EXAMPLE
    .\Verify-DiscordTunnel.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipHttps
)

$ErrorActionPreference = 'Continue'
$script:results = New-Object System.Collections.ArrayList

function Write-Head($t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Add-Result($name, $ok, $detail) {
    [void]$script:results.Add([pscustomobject]@{ Test = $name; Ok = [bool]$ok; Detail = $detail })
    if ($ok) { Write-Host ("  [PASS] {0,-28} {1}" -f $name, $detail) -ForegroundColor Green }
    else     { Write-Host ("  [FAIL] {0,-28} {1}" -f $name, $detail) -ForegroundColor Red }
}
function Write-Info($t) { Write-Host "         $t" -ForegroundColor Gray }

function Get-WarpCli {
    $cmd = Get-Command warp-cli -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $p = Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe'
    if (Test-Path $p) { return $p }
    return $null
}

$cli = Get-WarpCli
Write-Head 'Discord / Zero Trust dogrulama'
Write-Info ("Tarih: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

# 1) Servis + durum
$svc = Get-Service -Name 'CloudflareWARP' -ErrorAction SilentlyContinue
Add-Result 'WARP servisi' ($null -ne $svc -and $svc.Status -eq 'Running') $(if ($svc) { [string]$svc.Status } else { 'kurulu degil' })

$statusText = ''
if ($cli) {
    $statusText = (& $cli --accept-tos status 2>&1 | Out-String).Trim()
    Add-Result 'WARP baglantisi' ($statusText -match 'Connected') (($statusText -replace "\s+", ' '))
} else {
    Add-Result 'warp-cli' $false 'bulunamadi'
}

# 2) Takim kaydi
if ($cli) {
    $reg = (& $cli --accept-tos registration show 2>&1 | Out-String)
    $org = ''
    if ($reg -match 'Organization:\s*(.+)') { $org = $Matches[1].Trim() }
    $accId = ''
    if ($reg -match 'Account ID:\s*([0-9a-fA-F]{32})') { $accId = $Matches[1] }
    Add-Result 'Zero Trust takimi' ($reg -match 'Account type:\s*Team') $(if ($org) { "org=$org" } else { 'kayit yok' })
    if ($accId) { Write-Info "Account ID: $accId" }
}

# 3) Protokol + split tunnel listesi
if ($cli) {
    $settings = (& $cli --accept-tos settings 2>&1 | Out-String)
    $proto = ''
    if ($settings -match 'WARP tunnel protocol:\s*(\S+)') { $proto = $Matches[1] }
    Add-Result 'Tunel protokolu' ($proto -match 'MASQUE|WireGuard') $(if ($proto) { $proto } else { 'bilinmiyor' })
    Write-Info $(if ($proto -eq 'MASQUE') { 'MASQUE aktif (UDP/443, HTTP/3) - hedef durum.' } else { 'WireGuard aktif; DPI takilmalarina karsi MASQUE onerilir.' })

    $listText = ((& $cli --accept-tos tunnel ip list 2>&1 | Out-String) + (& $cli --accept-tos tunnel host list 2>&1 | Out-String))
    $ruleCount = ([regex]::Matches($listText, '(?m)^\s{2,}\S+')).Count
    Add-Result 'Split tunnel kurali' ($ruleCount -ge 100) ("$ruleCount kural")
    foreach ($needle in @('discord.com', 'gateway.discord.gg', '66.22.')) {
        Add-Result "Kural: $needle" ($listText -match [regex]::Escape($needle)) $(if ($listText -match [regex]::Escape($needle)) { 'listede' } else { 'eksik' })
    }
}

# 4) DNS
$dnsTargets = @('discord.com', 'gateway.discord.gg', 'cdn.discordapp.com')
foreach ($name in $dnsTargets) {
    try {
        $ips = @(Resolve-DnsName -Name $name -Type A -ErrorAction Stop | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress -Unique)
        Add-Result "DNS $name" ($ips.Count -gt 0 -and $ips[0] -notmatch '^(0\.0\.0\.0|127\.0\.0\.1)$') ($ips -join ', ')
    } catch {
        Add-Result "DNS $name" $false $_.Exception.Message
    }
}

# 5) TCP 443
try {
    $t = Test-NetConnection -ComputerName 'gateway.discord.gg' -Port 443 -WarningAction SilentlyContinue
    Add-Result 'TCP 443 gateway' ([bool]$t.TcpTestSucceeded) ("remote=" + $t.RemoteAddress)
} catch {
    Add-Result 'TCP 443 gateway' $false $_.Exception.Message
}

# 6) HTTPS API
if (-not $SkipHttps) {
    try {
        $r = Invoke-WebRequest -Uri 'https://discord.com/api/v9/gateway' -UseBasicParsing -TimeoutSec 20
        $ok = ($r.StatusCode -eq 200 -and $r.Content -match 'gateway\.discord\.gg')
        Add-Result 'HTTPS /api/v9/gateway' $ok ("HTTP $($r.StatusCode)")
    } catch {
        Add-Result 'HTTPS /api/v9/gateway' $false $_.Exception.Message
    }

    try {
        $r2 = Invoke-WebRequest -Uri 'https://discord.com' -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 0 -ErrorAction Stop
        Add-Result 'HTTPS discord.com' ($r2.StatusCode -eq 200) ("HTTP $($r2.StatusCode)")
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Add-Result 'HTTPS discord.com' ([bool]($code -ge 200 -and $code -lt 400)) ("HTTP $code")
    }
}

# 7) Uygulama
$proc = @(Get-Process -Name 'Discord' -ErrorAction SilentlyContinue)
Add-Result 'Discord uygulamasi' ($proc.Count -gt 0) ("{0} surec" -f $proc.Count)

# Ozet
Write-Head 'Ozet'
$fail = @($script:results | Where-Object { -not $_.Ok })
Write-Host ("  Toplam test : {0}" -f $script:results.Count) -ForegroundColor Gray
Write-Host ("  Basarili    : {0}" -f ($script:results.Count - $fail.Count)) -ForegroundColor Green
Write-Host ("  Basarisiz   : {0}" -f $fail.Count) -ForegroundColor $(if ($fail.Count -eq 0) { 'Green' } else { 'Red' })

if ($fail.Count -gt 0) {
    Write-Host ''
    Write-Host '  Basarisiz testler:' -ForegroundColor Red
    $fail | ForEach-Object { Write-Host ("   - {0}: {1}" -f $_.Test, $_.Detail) -ForegroundColor Red }
    exit 1
}

Write-Host ''
Write-Host '  Tum testler gecti. Discord Zero Trust tuneli uzerinden calisiyor.' -ForegroundColor Green
exit 0
