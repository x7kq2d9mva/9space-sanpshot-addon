#!/usr/bin/env sh
# Probe whether a Dahua/Amcrest NVR supports the HTTP snapshot CGI.
# Usage: sh test_snapshot_cgi.sh <NVR_HOST> <USERNAME> <PASSWORD> [CHANNELS] [PORT]
#   CHANNELS: space/comma list of channel numbers to try (default "0 1")
#   PORT:     NVR HTTP port (default 80)
# Example: sh test_snapshot_cgi.sh 192.168.1.200 admin secret "0 1 2 3" 80

NVR="$1"
USER="$2"
PASS="$3"
CHANNELS="${4:-0 1}"
PORT="${5:-80}"

if [ -z "$NVR" ] || [ -z "$USER" ] || [ -z "$PASS" ]; then
    echo "Usage: sh test_snapshot_cgi.sh <NVR_HOST> <USERNAME> <PASSWORD> [CHANNELS] [PORT]"
    exit 1
fi

# Normalise commas to spaces so "0,1,2" and "0 1 2" both work.
CHANNELS=$(echo "$CHANNELS" | tr ',' ' ')

echo "[INFO] NVR: http://${NVR}:${PORT}  user: ${USER}"
echo "[INFO] Channels: ${CHANNELS}"
echo ""

any=0
for ch in $CHANNELS; do
    for p in \
        "/cgi-bin/snapshot.cgi?channel=${ch}" \
        "/cgi-bin/snapshot.cgi?channel=${ch}&subtype=0" \
        "/cgi-bin/snapshot.cgi?channel=${ch}&type=0"; do

        url="http://${NVR}:${PORT}${p}"
        out="/tmp/cgi_ch${ch}.jpg"

        t=$(date +%s%3N 2>/dev/null || echo 0)
        code=$(curl -sS --digest -u "${USER}:${PASS}" -w "%{http_code}" -o "$out" "$url" 2>/dev/null)
        t2=$(date +%s%3N 2>/dev/null || echo 0)
        ms=$((t2 - t))

        sig=$(head -c3 "$out" 2>/dev/null | od -An -tx1 | tr -d ' \n')

        if [ "$code" = "200" ] && [ "$sig" = "ffd8ff" ]; then
            echo "[ OK ] ${p} -> HTTP ${code}, ${ms}ms, valid JPEG (${out})"
            any=1
        else
            echo "[FAIL] ${p} -> HTTP ${code}, ${ms}ms, sig=${sig}"
            rm -f "$out"
        fi
    done
done

echo ""
if [ "$any" = "1" ]; then
    echo "[RESULT] NVR SUPPORTS the HTTP snapshot CGI. Use the [OK] URL above."
else
    echo "[RESULT] No working CGI variant found. Check port/credentials, or this model may be RTSP-only."
fi
