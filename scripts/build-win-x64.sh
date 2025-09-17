#!/bin/zsh
set -euo pipefail

APP_NAME="Space"
ICON_PATH="assets/space_icon.ico"
OUT_DIR="${HOME}"

echo "Building ${APP_NAME} for Windows x64..."
echo "If on Apple Silicon, ensure Rosetta and Wine are installed and in PATH."

npx nativefier@55.0.1 "https://space.studiofritzgnad.de" \
  --name "${APP_NAME}" \
  --platform windows \
  --arch x64 \
  --icon "${ICON_PATH}" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --win32metadata '{"CompanyName":"Studio Fritz Gnad","FileDescription":"Space","ProductName":"Space"}' \
  --out "${OUT_DIR}"
echo "Done. Output at ${OUT_DIR}"


