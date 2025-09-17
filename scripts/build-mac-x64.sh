#!/bin/zsh
set -euo pipefail

APP_NAME="Space"
ICON_PATH="assets/space_icon.png"
OUT_DIR="${HOME}"

echo "Building ${APP_NAME} for macOS x64..."
npx nativefier@55.0.1 "https://space.studiofritzgnad.de" \
  --name "${APP_NAME}" \
  --platform mac \
  --arch x64 \
  --icon "${ICON_PATH}" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --out "${OUT_DIR}"
echo "Done. Output at ${OUT_DIR}"


