#!/bin/zsh
set -euo pipefail

APP_NAME="Space"
ICON_PATH="assets/space_icon.png"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
OUT_DIR="$(dirname "${SCRIPT_DIR}")"
USER_DATA_DIR="${HOME}/Library/Application Support/${APP_NAME}"

# Source VERSION from build.sh
source "${SCRIPT_DIR}/build.sh"

echo "Building ${APP_NAME} for macOS arm64..."

# Ensure the user data directory exists
mkdir -p "${USER_DATA_DIR}"

npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
  --name "${APP_NAME}" \
  --platform mac \
  --arch arm64 \
  --icon "${ICON_PATH}" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --out "${OUT_DIR}" \
  --user-data-dir "${USER_DATA_DIR}" \
  --app-version "${VERSION}" \
  --build-version "${VERSION}"

echo "Done. Output at ${OUT_DIR}"

# Compress the build output
echo "Compressing build..."
APP_DIR=$(find "${OUT_DIR}" -maxdepth 1 -name "${APP_NAME}-darwin-arm64" -type d | head -n 1)
if [[ -d "${APP_DIR}" ]]; then
  ZIP_NAME="${APP_NAME}-darwin-arm64_${VERSION}.zip"
  cd "${OUT_DIR}"
  zip -r -q "${ZIP_NAME}" "$(basename "${APP_DIR}")"
  echo "Compressed to ${OUT_DIR}/${ZIP_NAME}"
else
  echo "Warning: Could not find app directory to compress"
fi