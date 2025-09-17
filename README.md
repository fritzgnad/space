## Space — Nativefier desktop wrappers

Create Nativefier desktop apps for `https://space.studiofritzgnad.de` for:

- **Windows x64**
- **macOS Apple Silicon (arm64)**
- **macOS Intel (x64)**

Icons live in `assets/`:

- PNG: `assets/space_icon.png` (macOS)
- ICO: `assets/space_icon.ico` (Windows)

### Prerequisites

- Node.js 18+
- Nativefier (used via `npx nativefier@55.0.1`, pinned)
- macOS: For building Windows on Apple Silicon, install Rosetta and Wine

### Local builds

macOS arm64:

```bash
npx nativefier@55.0.1 "https://space.studiofritzgnad.de" \
  --name "Space" \
  --platform mac \
  --arch arm64 \
  --icon "assets/space_icon.png" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --out "$HOME"
```

macOS x64 (also works on Apple Silicon):

```bash
npx nativefier@55.0.1 "https://space.studiofritzgnad.de" \
  --name "Space" \
  --platform mac \
  --arch x64 \
  --icon "assets/space_icon.png" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --out "$HOME"
```

Windows x64 from macOS:

```bash
# Apple Silicon only: install Rosetta
softwareupdate --install-rosetta --agree-to-license

# Ensure Wine is installed and available in PATH (example path)
export PATH="/Applications/Wine Stable.app/Contents/Resources/wine/bin:$PATH"
wine64 --version

npx nativefier@55.0.1 "https://space.studiofritzgnad.de" \
  --name "Space" \
  --platform windows \
  --arch x64 \
  --icon "assets/space_icon.ico" \
  --single-instance \
  --disable-dev-tools \
  --browserwindow-options '{"frame":true,"fullscreenable":true}' \
  --win32metadata '{"CompanyName":"Studio Fritz Gnad","FileDescription":"Space","ProductName":"Space"}' \
  --out "$HOME"
```

### NPM scripts

```bash
npm run build:mac:arm64
npm run build:mac:x64
npm run build:win:x64
npm run icons:check
```

### CI (GitHub Actions)

- On push/PR to `main`, artifacts for macOS arm64/x64 and Windows x64 are built and uploaded.
- On tags matching `v*`, artifacts are attached to a GitHub Release.
- Optional macOS codesigning/notarization and Windows installer packaging are supported via secrets. If secrets are not provided, the jobs still produce unsigned zips.

#### macOS signing/notarization secrets (optional)

- `APPLE_ID` — Apple ID email
- `APPLE_APP_SPECIFIC_PASSWORD` — app-specific password for notarization
- `APPLE_TEAM_ID` — Team ID
- `MAC_CERT_P12_BASE64` — base64 of Developer ID Application certificate `.p12`
- `MAC_CERT_PASSWORD` — password for the `.p12`

#### Windows installer secrets (optional)

None required for a basic Inno Setup installer. If you want code-signing, add your own signtool step and secrets.

### License

MIT


