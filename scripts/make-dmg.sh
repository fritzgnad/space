#!/bin/bash
set -euo pipefail

# Packages a .app into a compressed DMG with drag-and-drop install layout:
# an /Applications symlink, a background image telling the user to drag the
# app into the Applications folder, and Finder icon positions to match.
# Icon coordinates must match scripts/make-dmg-background.py.
#
# Usage: make-dmg.sh <Space.app> <output.dmg> [volume-name]

APP="${1:?Usage: make-dmg.sh <app-bundle> <output.dmg> [volume-name]}"
DMG_OUT="${2:?missing output dmg path}"
VOLNAME="${3:-Space}"

ASSETS="$(cd "$(dirname "$0")/../assets" && pwd)"
APP_NAME="$(basename "${APP}")"
STAGE="$(mktemp -d)"
RW_DMG="$(mktemp -u).dmg"
MOUNT="$(mktemp -d)"
trap 'hdiutil detach "${MOUNT}" >/dev/null 2>&1 || true; rm -rf "${STAGE}" "${RW_DMG}"' EXIT

# ditto preserves signatures, extended attributes, and symlinks.
ditto "${APP}" "${STAGE}/${APP_NAME}"
ln -s /Applications "${STAGE}/Applications"

# Multi-resolution background so it stays sharp on Retina displays.
mkdir "${STAGE}/.background"
tiffutil -cathidpicheck "${ASSETS}/dmg-background.png" "${ASSETS}/dmg-background@2x.png" \
  -out "${STAGE}/.background/background.tiff"

# Build read-write first so Finder can store the window layout (.DS_Store),
# then compress to the final read-only image.
hdiutil create -volname "${VOLNAME}" -srcfolder "${STAGE}" -ov -format UDRW "${RW_DMG}" >/dev/null
hdiutil attach "${RW_DMG}" -nobrowse -mountpoint "${MOUNT}" >/dev/null

if ! osascript <<EOF
tell application "Finder"
  tell disk (POSIX file "${MOUNT}" as alias)
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 860, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 100
    set background picture of viewOptions to file ".background:background.tiff"
    set position of item "${APP_NAME}" of container window to {165, 200}
    set position of item "Applications" of container window to {495, 200}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF
then
  echo "WARNING: Finder layout scripting failed; DMG will use default layout"
fi

sync
hdiutil detach "${MOUNT}" >/dev/null
hdiutil convert "${RW_DMG}" -format UDZO -o "${DMG_OUT}" -ov >/dev/null
echo "Created: ${DMG_OUT}"
