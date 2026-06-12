#!/bin/bash
set -euo pipefail

# Packages a .app into a compressed DMG with an /Applications symlink for
# drag-and-drop install.
#
# Usage: make-dmg.sh <Space.app> <output.dmg> [volume-name]

APP="${1:?Usage: make-dmg.sh <app-bundle> <output.dmg> [volume-name]}"
DMG_OUT="${2:?missing output dmg path}"
VOLNAME="${3:-Space}"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

# ditto preserves signatures, extended attributes, and symlinks.
ditto "${APP}" "${STAGE}/$(basename "${APP}")"
ln -s /Applications "${STAGE}/Applications"

hdiutil create -volname "${VOLNAME}" -srcfolder "${STAGE}" -ov -format UDZO "${DMG_OUT}"
echo "Created: ${DMG_OUT}"
