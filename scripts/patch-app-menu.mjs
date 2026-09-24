#!/usr/bin/env node
// Adds a "Reset Cache and Cookies…" item to the top of the macOS app menu
// (the "Space" menu) in a built app's bundled main.js.
//
// Nativefier only offers Edit → Clear App Data, which wipes *all* site data
// (local storage, IndexedDB, service workers, …) and leaves the page running
// on the now-stale state. The item added here does the narrower, far more
// common thing: drop the HTTP cache, delete cookies (signing the user out),
// and reload. Nativefier is archived upstream, so we patch its bundled
// main.js after the build rather than carrying a fork.
//
// Usage: node scripts/patch-app-menu.mjs <path-to-app/lib/main.js>

import { readFile, writeFile } from 'node:fs/promises';

// Also grepped for by the CI "Verify app arch and patches" step, so a silently
// unpatched build can never ship.
const MARKER = 'Reset Cache and Cookies';

// Nativefier builds the macOS app menu as `electronMenu`; macOS renders its
// label as the app name, which is why this shows up as the "Space" menu.
const ANCHOR =
  /(const electronMenu\s*=\s*\{\s*label:\s*'E&lectron',\s*submenu:\s*\[)/;

// Sits above Services, where macOS apps put app-level actions. `mainWindow`,
// `electron_1` and `log` are all in scope at this point in generateMenu().
const MENU_ITEM = `
                {
                    label: 'Reset Cache and Cookies…',
                    click: (item, focusedWindow) => {
                        const targetWindow = focusedWindow || mainWindow;
                        if (!targetWindow) {
                            log.error('Reset Cache and Cookies: no window available');
                            return;
                        }
                        (async () => {
                            const { response } = await electron_1.dialog.showMessageBox(targetWindow, {
                                type: 'warning',
                                buttons: ['Reset', 'Cancel'],
                                defaultId: 1,
                                cancelId: 1,
                                title: 'Reset cache and cookies',
                                message: 'Reset cache and delete cookies?',
                                detail: 'This clears cached files and signs you out of Space. The window reloads afterwards.',
                            });
                            if (response !== 0) {
                                return;
                            }
                            const { session } = targetWindow.webContents;
                            await session.clearCache();
                            await session.clearStorageData({ storages: ['cookies'] });
                            targetWindow.webContents.reloadIgnoringCache();
                        })().catch((err) => log.error('Reset Cache and Cookies ERROR', err));
                    },
                },
                {
                    type: 'separator',
                },`;

const mainJsPath = process.argv[2];
if (!mainJsPath) {
  console.error('Usage: patch-app-menu.mjs <path-to-app/lib/main.js>');
  process.exit(1);
}

const source = await readFile(mainJsPath, 'utf8');

if (source.includes(MARKER)) {
  console.log(`App menu already patched, nothing to do: ${mainJsPath}`);
  process.exit(0);
}

if (!ANCHOR.test(source)) {
  console.error(
    `ERROR: macOS app menu template not found in ${mainJsPath}. ` +
      'Nativefier likely changed its menu code — update the anchor in scripts/patch-app-menu.mjs.',
  );
  process.exit(1);
}

await writeFile(mainJsPath, source.replace(ANCHOR, `$1${MENU_ITEM}`), 'utf8');

console.log(`Added "Reset Cache and Cookies…" to the app menu in: ${mainJsPath}`);
