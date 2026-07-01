param(
    # Example: .\test_snapshot_cgi.ps1 192.168.1.200 admin 1
    [Parameter(Mandatory=$true, Position=0)]
    [string]$NvrHost,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$Username,
    [Parameter(Mandatory=$true, Position=2)]
    [string]$Password,
    # Channel numbers to probe (as they appear in the CGI URL). Default tries 0 and 1.
    [Parameter(Position=3)]
    [int[]]$Channels = @(0, 1),
    # NVR HTTP port (usually 80).
    [int]$Port = 80
)

$ErrorActionPreference = "Stop"

$OutDir = (Get-Location).Path

# Common Dahua/Amcrest snapshot CGI URL variants.
$PathTemplates = @(
    "/cgi-bin/snapshot.cgi?channel={0}",
    "/cgi-bin/snapshot.cgi?channel={0}&subtype=0",
    "/cgi-bin/snapshot.cgi?channel={0}&type=0"
)

function Test-Jpeg([string]$file) {
    if (-not (Test-Path $file)) { return $false }
    $fs = [System.IO.File]::OpenRead($file)
    try {
        if ($fs.Length -lt 3) { return $false }
        $b = New-Object byte[] 3
        [void]$fs.Read($b, 0, 3)
        return ($b[0] -eq 0xFF -and $b[1] -eq 0xD8 -and $b[2] -eq 0xFF)
    } finally {
        $fs.Close()
    }
}

Write-Host "[INFO] NVR: http://{0}:{1}  user: {2}" -f $NvrHost, $Port, $Username
Write-Host "[INFO] Probing channels: $($Channels -join ', ')"
Write-Host ""

$anySuccess = $false

foreach ($ch in $Channels) {
    foreach ($tpl in $PathTemplates) {
        $path = [string]::Format($tpl, $ch)
        $url = "http://{0}:{1}{2}" -f $NvrHost, $Port, $path
        $out = Join-Path $OutDir ("cgi_ch{0}.jpg" -f $ch)

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $code = (& curl.exe -sS --digest -u "$Username`:$Password" -w "%{http_code}" -o $out $url) 2>$null
        $sw.Stop()
        $ms = [int]$sw.Elapsed.TotalMilliseconds
        $code = "$code".Trim()

        $size = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
        $isJpeg = Test-Jpeg $out

        if ($code -eq "200" -and $isJpeg) {
            Write-Host ("[ OK ] {0}  -> HTTP {1}, {2} bytes, {3} ms  (valid JPEG => {4})" -f $path, $code, $size, $ms, $out) -ForegroundColor Green
            $anySuccess = $true
        } else {
            Write-Host ("[FAIL] {0}  -> HTTP {1}, {2} bytes, {3} ms, jpeg={4}" -f $path, $code, $size, $ms, $isJpeg) -ForegroundColor DarkGray
            if (Test-Path $out) { Remove-Item -Force $out }
        }
    }
}

Write-Host ""
if ($anySuccess) {
    Write-Host "[RESULT] Your NVR SUPPORTS the HTTP snapshot CGI. Use the [OK] URL above." -ForegroundColor Green
} else {
    Write-Host "[RESULT] No working CGI variant found. Check port/credentials, or this model may only support RTSP." -ForegroundColor Yellow
}
