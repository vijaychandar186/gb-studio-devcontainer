#!/bin/bash
set -euo pipefail

TMP_DEB_FILE="/tmp/gb-studio-linux-debian.deb"
LATEST_RELEASE_API="https://api.github.com/repos/chrismaltby/gb-studio/releases/latest"

echo ">>> Updating apt index..."
sudo apt-get update -q

echo ">>> Installing runtime dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl ca-certificates \
  xvfb x11vnc novnc websockify openbox xterm x11-utils dbus-x11 \
  libgtk-3-0 libnotify4 libnss3 libxtst6 xdg-utils libatspi2.0-0 \
  libdrm2 libgbm1 libxcb-dri3-0 libglib2.0-bin libasound2t64 python3-xdg

echo ">>> Resolving latest GB Studio Debian release from GitHub..."
DEB_URL="$(curl -fsSL "$LATEST_RELEASE_API" | python3 -c 'import json,sys
data=json.load(sys.stdin)
assets=data.get("assets", [])
url=""
for asset in assets:
    if asset.get("name") == "gb-studio-linux-debian.deb":
        url=asset.get("browser_download_url", "")
        break
print(url)
')"

if [ -n "$DEB_URL" ]; then
  echo ">>> Downloading latest package: $DEB_URL"
  curl -fL "$DEB_URL" -o "$TMP_DEB_FILE"
  DEB_FILE="$TMP_DEB_FILE"
else
  echo "ERROR: Failed to fetch latest GB Studio .deb from GitHub releases."
  exit 1
fi

echo ">>> Installing GB Studio package..."
sudo dpkg -i "$DEB_FILE" || true
sudo DEBIAN_FRONTEND=noninteractive apt-get -f install -y

echo ">>> Done. Binary: /usr/bin/gb-studio"