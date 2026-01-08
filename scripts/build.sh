#!/bin/zsh
set -euo pipefail

APP_NAME="Space"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
OUT_BASE_DIR="$(dirname "${SCRIPT_DIR}")"
VERSION="1.6"

# Define platform-specific icon paths
ICON_PATH_MAC="${SCRIPT_DIR}/../assets/space_icon.png"
ICON_PATH_WIN="${SCRIPT_DIR}/../assets/space_icon.ico"

# Note: The Windows build requires Wine to be installed on macOS.
# You can install it using Homebrew with the command: `brew install --cask wine-stable`
# This is necessary for handling platform-specific metadata, like the app's icon and version info.

# Define a list of build targets as "platform:arch"
declare -a targets=("mac:arm64" "mac:x64" "windows:x64")

for target in "${targets[@]}"; do
  # Split the target string into platform and architecture
  platform="${target%%:*}"
  arch="${target##*:}"

  echo "Building ${APP_NAME} for ${platform} (${arch})..."

  # Assign the correct icon path based on the platform
  if [[ "${platform}" == "windows" ]]; then
    ICON_PATH="${ICON_PATH_WIN}"
  else
    ICON_PATH="${ICON_PATH_MAC}"
  fi

  # Define unique output directory for each build
  OUT_DIR="${OUT_BASE_DIR}/${APP_NAME}_${platform}_${arch}"
  mkdir -p "${OUT_DIR}"

  # Set user data directory only for macOS (Windows uses default persistent location)
  if [[ "${platform}" == "mac" ]]; then
    USER_DATA_DIR="${HOME}/Library/Application Support/${APP_NAME}"
    mkdir -p "${USER_DATA_DIR}"
    USER_DATA_ARG="--user-data-dir \"${USER_DATA_DIR}\""
  else
    USER_DATA_ARG=""
  fi

  # The main Nativefier command
  npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
    --name "${APP_NAME}" \
    --platform "${platform}" \
    --arch "${arch}" \
    --icon "${ICON_PATH}" \
    --single-instance \
    --disable-dev-tools \
    --browserwindow-options '{"frame":true,"fullscreenable":true}' \
    --out "${OUT_DIR}" \
    ${USER_DATA_ARG} \
    --app-version "${VERSION}" \
    --build-version "${VERSION}" \
    --win32metadata '{"CompanyName":"Studio Fritz Gnad","FileDescription":"Space","ProductName":"Space"}'

  echo "Done. Output at ${OUT_DIR}"
  
  # Compress the build output
  echo "Compressing build..."
  
  # Determine the platform name for the zip file
  if [[ "${platform}" == "mac" ]]; then
    PLATFORM_NAME="darwin"
  elif [[ "${platform}" == "windows" ]]; then
    PLATFORM_NAME="win32"
  else
    PLATFORM_NAME="${platform}"
  fi
  
  # Find the generated app directory
  APP_DIR=$(find "${OUT_DIR}" -maxdepth 1 -name "${APP_NAME}-${PLATFORM_NAME}-${arch}" -type d | head -n 1)
  
  if [[ -d "${APP_DIR}" ]]; then
    ZIP_NAME="${APP_NAME}-${PLATFORM_NAME}-${arch}_${VERSION}.zip"
    cd "${OUT_DIR}"
    zip -r -q "${ZIP_NAME}" "$(basename "${APP_DIR}")"
    echo "Compressed to ${OUT_DIR}/${ZIP_NAME}"
  else
    echo "Warning: Could not find app directory to compress"
  fi
done

echo "All builds completed."