#!/bin/bash
set -euo pipefail

# Signs an Electron .app bundle for Developer ID distribution + notarization.
#
# Signs inside-out (nested Mach-O binaries, then frameworks, then helper
# apps, then the main app), applying the hardened runtime and entitlements
# to every binary. A plain `codesign --deep` is NOT enough: it does not
# propagate entitlements to nested code, so Electron's helper processes
# (renderer/GPU/plugin) would run without the JIT and camera/mic
# entitlements and crash or lose media access under the hardened runtime.
#
# Usage: sign-mac-app.sh <Space.app> <signing-identity> <entitlements.plist>
#        (identity "-" signs ad-hoc, useful for local testing)

APP="${1:?Usage: sign-mac-app.sh <app-bundle> <identity> <entitlements>}"
IDENTITY="${2:?missing signing identity}"
ENT="${3:?missing entitlements plist}"

TIMESTAMP_FLAG="--timestamp"
if [[ "${IDENTITY}" == "-" ]]; then
  # Apple's timestamp service rejects ad-hoc signatures.
  TIMESTAMP_FLAG="--timestamp=none"
fi

sign() {
  /usr/bin/codesign --force --options runtime ${TIMESTAMP_FLAG} \
    --entitlements "${ENT}" --sign "${IDENTITY}" "$1"
  echo "signed: $1"
}

FRAMEWORKS="${APP}/Contents/Frameworks"

# 1. Standalone Mach-O files inside Frameworks (dylibs, native modules,
#    chrome_crashpad_handler, Squirrel's ShipIt, ...), deepest paths first.
#    Helper-app internals are excluded; they are signed via their bundles.
while IFS= read -r f; do
  if file -b "${f}" | grep -q 'Mach-O'; then
    sign "${f}"
  fi
done < <(find "${FRAMEWORKS}" \( -type f -perm -u+x -o -name '*.dylib' -o -name '*.node' \) \
           ! -path '*/Frameworks/*.app/*' \
         | awk -F/ '{print NF "\t" $0}' | sort -rn | cut -f2-)

# 2. Framework bundles.
for fw in "${FRAMEWORKS}"/*.framework; do
  [[ -d "${fw}" ]] && sign "${fw}"
done

# 3. Helper app bundles.
for helper in "${FRAMEWORKS}"/*.app; do
  [[ -d "${helper}" ]] && sign "${helper}"
done

# 4. The main app bundle itself.
sign "${APP}"

/usr/bin/codesign --verify --deep --strict --verbose=2 "${APP}"
echo "Signature verified: ${APP}"
