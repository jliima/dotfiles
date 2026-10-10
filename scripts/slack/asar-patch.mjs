#!/usr/bin/env node
// Patches a pristine Slack desktop app.asar so every webContents the app creates gets a user-writable theme file
// (~/.config/slack-theme/theme.css) inserted with insertCSS(), and the file is watched, so a change restyles the
// open windows without a reload.
//
// Usage: node asar-patch.mjs <input-asar> <output-asar>
//
// Slack's main process is one minified bundle (dist/boot.bundle.cjs, package.json "main"). The bootstrap goes in front
// of it, so its `app.on('web-contents-created')` listener exists before the first window does. Nothing of Slack's own
// code is touched or relied on, so it survives updates as long as the entry file keeps its name. Slack's Electron has
// the asar integrity fuse off (see patch.sh), otherwise a modified asar would not start.
import fs from 'node:fs';
import { readAsar, listFiles, extractFileBuffer, repackWithReplacements } from '../claude-desktop/lib/asar-lib.mjs';

const [, , inPath, outPath] = process.argv;
if (!inPath || !outPath) {
  console.error('usage: asar-patch.mjs <input-asar> <output-asar>');
  process.exit(2);
}

const ENTRY = '/dist/boot.bundle.cjs';
const MARKER = '/*__THEMER_THEME_BOOTSTRAP__*/';

// Runs in Slack's main process. Plain ES5-ish, one function, never throws into Slack's startup.
const bootstrap = String.raw`(function () {
  try {
    var fs = require('node:fs');
    var path = require('node:path');
    var os = require('node:os');
    var electron = require('electron');
    var dir = path.join(os.homedir(), '.config', 'slack-theme');
    var file = path.join(dir, 'theme.css');
    var keys = new WeakMap();

    var load = function () {
      try { return fs.readFileSync(file, 'utf8'); } catch (e) { return null; }
    };
    // Inserts the current theme into one webContents and removes the copy inserted before it, if any.
    var apply = function (wc, fresh) {
      try {
        if (wc.isDestroyed() || String(wc.getURL()).indexOf('devtools://') === 0) return;
        var css = load();
        if (css == null) return;
        var old = fresh ? undefined : keys.get(wc);
        if (fresh) keys.delete(wc);
        wc.insertCSS(css, { cssOrigin: 'user' }).then(function (key) {
          if (old !== undefined) { try { wc.removeInsertedCSS(old); } catch (e) {} }
          keys.set(wc, key);
          try { wc.invalidate(); } catch (e) {}
        }).catch(function (e) { console.error('[themer] insertCSS failed', e); });
      } catch (e) { console.error('[themer] apply failed', e); }
    };
    var applyAll = function () {
      electron.webContents.getAllWebContents().forEach(function (wc) { apply(wc, false); });
    };

    electron.app.on('web-contents-created', function (event, wc) {
      // A new document starts without the inserted CSS, so a page load always inserts afresh.
      wc.on('dom-ready', function () { apply(wc, true); });
      wc.on('did-navigate', function () { apply(wc, true); });
    });

    // Watch the folder, not the file: Themer replaces the file, which ends a watch on the old one.
    fs.mkdirSync(dir, { recursive: true });
    var timer = null;
    fs.watch(dir, function (kind, name) {
      if (name && name !== 'theme.css') return;
      clearTimeout(timer);
      timer = setTimeout(applyAll, 150);
    }).on('error', function () {});
  } catch (e) { console.error('[themer] bootstrap failed', e); }
})();
`;

const { data, header, dataOffset } = readAsar(inPath);
const files = listFiles(header);
const entry = files.find((f) => f.path === ENTRY);
if (!entry) {
  throw new Error(`${ENTRY} not found in app.asar; Slack has changed shape`);
}

const original = extractFileBuffer(data, dataOffset, entry).toString('utf8');
if (original.includes(MARKER)) {
  throw new Error(`${ENTRY} already looks patched (marker found); refusing to double-patch`);
}

const patched = MARKER + bootstrap.replace(/\s*\n\s*/g, '\n') + '\n' + original;
console.log(`patched ${ENTRY}: inserted the theme bootstrap in front of the main process bundle`);

const replacements = new Map([[ENTRY, Buffer.from(patched, 'utf8')]]);

// A V8 code cache for the entry file, if one ever ships, holds bytecode of the old source.
const jsc = files.find((f) => /compile-cache\/boot\.bundle\.cjs/.test(f.path));
if (jsc) {
  replacements.set(jsc.path, Buffer.alloc(0));
  console.log(`invalidated stale V8 code cache at ${jsc.path}`);
}

const rebuilt = repackWithReplacements(header, data, dataOffset, replacements);
fs.writeFileSync(outPath, rebuilt);
console.log(`wrote patched asar to ${outPath} (${rebuilt.length} bytes, was ${data.length})`);
