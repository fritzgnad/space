#!/bin/zsh
set -euo pipefail

# Injects camera/microphone usage descriptions and a stable bundle identifier
# into a built .app's Info.plist, then re-signs the bundle ad-hoc.
#
# Without the usage descriptions, macOS (TCC) silently denies camera/mic access
# and never shows the permission prompt, so WebRTC apps like WorkAdventure
# can't get media. The re-sign is mandatory: editing Info.plist invalidates the
# existing signature, and TCC refuses to attribute permission requests to an
# app with a broken signature — again a silent deny with no way to unblock.
# The stable bundle id keeps TCC grants intact across rebuilds (nativefier
# otherwise generates a different id every build).
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
BUNDLE_ID="de.studiofritzgnad.space"

set_key() {
  local key="$1" msg="$2"
  /usr/libexec/PlistBuddy -c "Add :${key} string ${msg}" "${PLIST}" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :${key} ${msg}" "${PLIST}"
}

set_key "NSCameraUsageDescription" "${CAM_MSG}"
set_key "NSMicrophoneUsageDescription" "${MIC_MSG}"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${PLIST}"

echo "Patched Info.plist with camera/microphone usage descriptions: ${PLIST}"

# Guard nativefier's app.on('activate') handler: it calls mainWindow.show()
# without checking the window exists, so activating the app (dock click)
# before the window is created crashes the main process with
# "Cannot read properties of undefined (reading 'show')". Nativefier is
# archived upstream, so we patch the bundled main.js here, pre-signing.
MAIN_JS="${APP_BUNDLE}/Contents/Resources/app/lib/main.js"
if [[ -f "${MAIN_JS}" ]]; then
  perl -0pi -e 's/if \(!hasVisibleWindows\) \{/if (!hasVisibleWindows && mainWindow) {/' "${MAIN_JS}"
  if grep -q 'hasVisibleWindows && mainWindow' "${MAIN_JS}"; then
    echo "Patched activate-handler mainWindow guard in: ${MAIN_JS}"
  else
    echo "ERROR: activate-handler pattern not found in ${MAIN_JS}"
    exit 1
  fi
fi

# Re-sign the whole bundle ad-hoc so the signature covers the patched plist.
codesign --force --deep --sign - "${APP_BUNDLE}"
codesign --verify --deep --strict "${APP_BUNDLE}"
echo "Re-signed ad-hoc and verified: ${APP_BUNDLE}"
