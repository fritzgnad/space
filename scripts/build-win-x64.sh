#!/bin/zsh
set -euo pipefail

APP_NAME="Space"
ICON_PATH="assets/space_icon.ico"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
OUT_DIR="$(dirname "${SCRIPT_DIR}")"

# Source VERSION from build.sh
source "${SCRIPT_DIR}/build.sh"

echo "Building ${APP_NAME} for Windows x64..."

# Note: Building Windows apps on macOS requires Wine
# Install with: brew install --cask wine-stable

# Set user data directory for Windows (using default Electron location)
# On Windows, Electron uses %APPDATA%/${APP_NAME} by default, but we can specify it explicitly
# For cross-platform builds from macOS, we'll let Nativefier use the default location
# which will be %APPDATA%\Space on Windows when the app runs

npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
  --name "${APP_NAME}" \
  --platform windows \
  --arch x64 \
  --icon "${ICON_PATH}" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --out "${OUT_DIR}" \
  --app-version "${VERSION}" \
  --build-version "${VERSION}" \
  --win32metadata '{"CompanyName":"Studio Fritz Gnad","FileDescription":"Space","ProductName":"Space"}'

echo "Done. Output at ${OUT_DIR}"

# Compress the build output
echo "Compressing build..."
APP_DIR=$(find "${OUT_DIR}" -maxdepth 1 -name "${APP_NAME}-win32-x64" -type d | head -n 1)
if [[ -d "${APP_DIR}" ]]; then
  ZIP_NAME="${APP_NAME}-win32-x64_${VERSION}.zip"
  cd "${OUT_DIR}"
  zip -r -q "${ZIP_NAME}" "$(basename "${APP_DIR}")"
  echo "Compressed to ${OUT_DIR}/${ZIP_NAME}"
else
  echo "Warning: Could not find app directory to compress"
fi
