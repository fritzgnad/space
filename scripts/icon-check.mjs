import { stat } from 'node:fs/promises';

async function ensureFile(path) {
  try {
    const s = await stat(path);
    if (!s.isFile()) throw new Error('not a file');
  } catch (e) {
    console.error(`Missing required icon: ${path}`);
    process.exit(1);
  }
}

await ensureFile('assets/space_icon.png');
await ensureFile('assets/space_icon.ico');

console.log('Icon check OK');


