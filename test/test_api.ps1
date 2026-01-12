param(
    # Example: .\test_api.ps1 192.168.1.10
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Ip
)

$ErrorActionPreference = "Stop"

# Fixed settings
$CameraId = 1
$Port = 8000
$BaseUrl = "http://{0}:{1}" -f $Ip, $Port

# Output directory = current directory
$OutDir = (Get-Location).Path

$resp = Join-Path $OutDir "resp.bin"
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$jpg = Join-Path $OutDir ("cam{0}_{1}.jpg" -f $CameraId, $ts)

# 1) Download raw response (binary)
$url = "{0}/api/camera/{1}" -f $BaseUrl.TrimEnd('/'), $CameraId
curl.exe -sS $url -o $resp

# 2) Extract JPEG part (if any) using Python
$py = @"
import os, re, sys
resp = r"$resp"
out  = os.path.join(os.path.dirname(resp), "snapshot.jpg")

data = open(resp, "rb").read()
boundary = b"BOUNDARY"

for p in data.split(b"--" + boundary):
    if b"Content-Type: image/jpeg" in p:
        i = p.find(b"\r\n\r\n")
        body = p[i+4:]
        if body.endswith(b"\r\n"):
            body = body[:-2]
        open(out, "wb").write(body)
        print("JPEG_SAVED", out, len(body))
        sys.exit(0)

m = re.search(br"\{.*\}", data, re.S)
print("NO_JPEG", (m.group(0).decode("utf-8","ignore") if m else "unknown"))
"@

$py | python.exe

# 3) Rename extracted JPEG to timestamped filename (if created)
$snap = Join-Path $OutDir "snapshot.jpg"
if (Test-Path $snap) {
    Move-Item -Force $snap $jpg
    Write-Host "Saved JPG => $jpg"
} else {
    Write-Host "No JPG extracted. Raw response saved to => $resp"
}
