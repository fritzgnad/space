## Space — Nativefier desktop wrappers

Create Nativefier desktop apps for `https://space.studiofritzgnad.de` for:

- **Windows x64**
- **macOS Apple Silicon (arm64)**
- **macOS Intel (x64)**

**Current Version**: 1.6

Icons live in `assets/`:

- PNG: `assets/space_icon.png` (macOS)
- ICO: `assets/space_icon.ico` (Windows)

### Persistent Login & Cookies

All builds use persistent session storage so you stay logged in across app restarts. Cookies are automatically saved and restored via Electron's user data directory:

- **macOS**: User data (including cookies) stored in `~/Library/Application Support/Space`
- **Windows**: User data (including cookies) stored in `%APPDATA%\Space` (default Electron location)

**Important**: Cookies persist automatically - no special configuration needed. The app uses Electron's built-in cookie storage which saves cookies to disk in the user data directory.

To clear login data and cookies, delete the respective directory:
- macOS: `rm -rf ~/Library/Application\ Support/Space`
- Windows: Delete `%APPDATA%\Space` folder

The app will remember your login as long as the website sets persistent cookies (typically when "Remember me" is checked during login).

### Prerequisites

- Node.js 18+
- Nativefier (used via `npx nativefier@52.0.0`, pinned)
- macOS: For building Windows on Apple Silicon, install Rosetta and Wine

### Local builds

macOS arm64:

```bash
npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
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
npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
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

npx nativefier@52.0.0 "https://space.studiofritzgnad.de" \
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

Build all platforms using the provided scripts:

```bash
npm run build:mac:arm64    # Build macOS Apple Silicon
npm run build:mac:x64      # Build macOS Intel
npm run build:win:x64      # Build Windows x64
npm run icons:check        # Verify icon files exist
```

**Build Output**: Apps are built in the project root:
- macOS: `Space-darwin-arm64/` and `Space-darwin-x64/`
- Windows: `Space-win32-x64/`

The scripts automatically compress builds to zip files (e.g., `Space-darwin-arm64_1.6.zip`).

### CI (GitHub Actions)

- **Automatic builds**: On push/PR to `main`, artifacts for macOS arm64/x64 and Windows x64 are built and uploaded as GitHub Actions artifacts.
- **Releases**: On tags matching `v*` (e.g., `v1.6`), artifacts are automatically attached to a GitHub Release.
- **Optional signing**: macOS codesigning/notarization is supported via secrets. If secrets are not provided, the jobs still produce unsigned zips.

Download the latest builds from the [Actions tab](https://github.com/fritzgnad/space/actions) or from [Releases](https://github.com/fritzgnad/space/releases) for tagged versions.

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


