#!/bin/bash
set -euo pipefail

pkill -x gb-studio 2>/dev/null || true
pkill -x x11vnc 2>/dev/null || true
pkill -x openbox 2>/dev/null || true
pkill -x Xvfb 2>/dev/null || true
pkill -x websockify 2>/dev/null || true
sleep 1
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# Locate noVNC web root and pick the best entry-point HTML file
NOVNC_WEB=""
for candidate in /usr/share/novnc /usr/share/novnc/utils/websockify /usr/share/novnc-core; do
  if [ -d "$candidate" ]; then
    NOVNC_WEB="$candidate"
    break
  fi
done
if [ -z "$NOVNC_WEB" ]; then
  NOVNC_WEB="$(find /usr/share -maxdepth 2 -name 'vnc_lite.html' -o -name 'vnc.html' 2>/dev/null | head -1 | xargs -r dirname)"
fi
if [ -z "$NOVNC_WEB" ]; then
  echo "ERROR: Could not locate noVNC web directory."
  exit 1
fi

if [ -f "$NOVNC_WEB/vnc.html" ]; then
  NOVNC_PAGE="vnc.html"
elif [ -f "$NOVNC_WEB/vnc_lite.html" ]; then
  NOVNC_PAGE="vnc_lite.html"
else
  NOVNC_PAGE="$(ls "$NOVNC_WEB"/*.html 2>/dev/null | head -1 | xargs -r basename)"
fi

echo ">>> noVNC web root: $NOVNC_WEB (page: $NOVNC_PAGE)"

echo ">>> Starting Xvfb..."
Xvfb :1 -screen 0 1280x800x24 &
sleep 2

echo ">>> Starting Openbox..."
DISPLAY=:1 openbox-session &
sleep 2

echo ">>> Starting x11vnc..."
mkdir -p "$HOME/.vnc"
x11vnc -display :1 -passwd password -rfbport 5901 -forever -noxdamage -quiet &
sleep 2

echo ">>> Starting noVNC..."
websockify --web="$NOVNC_WEB" 6080 localhost:5901 &
sleep 2

echo ">>> Launching GB Studio..."
DISPLAY=:1 nohup /usr/bin/gb-studio --no-sandbox --disable-gpu --disable-dev-shm-usage >/tmp/gb-studio.log 2>&1 &

if [ -n "${CODESPACE_NAME:-}" ]; then
  ACCESS_URL="https://${CODESPACE_NAME}-6080.app.github.dev/${NOVNC_PAGE}?autoconnect=1&password=password"
else
  ACCESS_URL="http://localhost:6080/${NOVNC_PAGE}?autoconnect=1&password=password"
fi

echo ""
echo "======================================================"
echo "  GB Studio is ready!"
echo "  Open: $ACCESS_URL"
echo "  VNC password: password"
echo "  Logs: /tmp/gb-studio.log"
echo "======================================================"