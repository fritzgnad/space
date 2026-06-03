#!/bin/zsh
set -euo pipefail

# Injects camera/microphone usage descriptions into a built .app's Info.plist.
# Without these keys, macOS (TCC) silently denies camera/mic access and never
# shows the permission prompt, so WebRTC apps like WorkAdventure can't get media.
#
# Usage: patch-mac-plist.sh /path/to/Space-darwin-<arch>

APP_PARENT="${1:?Usage: patch-mac-plist.sh <app-output-dir>}"

# Locate the .app bundle inside the given directory.
APP_BUNDLE=$(find "${APP_PARENT}" -maxdepth 1 -name "*.app" -type d | head -n 1)
if [[ -z "${APP_BUNDLE}" || ! -d "${APP_BUNDLE}" ]]; then
  echo "ERROR: No .app bundle found under ${APP_PARENT}"
  exit 1
fi

PLIST="${APP_BUNDLE}/Contents/Info.plist"
if [[ ! -f "${PLIST}" ]]; then
  echo "ERROR: Info.plist not found at ${PLIST}"
  exit 1
fi

CAM_MSG="Space uses your camera for video chat in the virtual space."
MIC_MSG="Space uses your microphone for voice chat in the virtual space."

set_key() {
  local key="$1" msg="$2"
  /usr/libexec/PlistBuddy -c "Add :${key} string ${msg}" "${PLIST}" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :${key} ${msg}" "${PLIST}"
}

set_key "NSCameraUsageDescription" "${CAM_MSG}"
set_key "NSMicrophoneUsageDescription" "${MIC_MSG}"

echo "Patched Info.plist with camera/microphone usage descriptions: ${PLIST}"
