#!/usr/bin/env node
// Patches a pristine claude-desktop app.asar so every webContents the app
// creates insertCSS()s an external, user-writable theme file once its page
// is ready.
//
// Usage: node claude-desktop-asar-patch.mjs <input-asar> <output-asar>
//
// Approach: register a single Electron `app.on('web-contents-created', ...)`
// listener that attaches a 'dom-ready' handler to every webContents the app
// ever creates (main window shell, claude.ai content tabs, popups, cowork
// artifacts view, everything), each time reading the theme file fresh and
// insertCSS()ing it. This is Electron's own standard "theme any page"
// pattern and doesn't depend on any of the app's own internal event wiring,
// so it stays correct even as the app's bundled code changes between
// releases. The snippet is inserted right after the "use strict" prologue
// of whichever bundled file is found to contain the app's own webContents
// setup code (used only to identify a file that's loaded early, at main
// process startup, before any window exists) so the listener is registered
// before the first webContents is created.
import fs from 'node:fs';
import { readAsar, listFiles, extractFileBuffer, repackWithReplacements } from './lib/asar-lib.mjs';

const [, , inPath, outPath] = process.argv;
if (!inPath || !outPath) {
  console.error('usage: claude-desktop-asar-patch.mjs <input-asar> <output-asar>');
  process.exit(2);
}

// Anchor used only to find the right file: the app's own drag-region fix,
// present in the same early-loaded bundle as its window/tab setup code.
const ANCHOR = '-webkit-app-region: no-drag !important';

const BOOTSTRAP =
  '(function(){try{' +
  'var __load=function(){' +
  'try{return require("node:fs").readFileSync(' +
  'require("node:path").join(require("node:os").homedir(),".config","claude-desktop-theme","theme.css"),' +
  '"utf8")}catch(__e){return null}};' +
  'var __apply=function(wc){' +
  'try{if(wc.isDestroyed())return;var __c=__load();if(__c==null)return;' +
  'wc.insertCSS(__c,{cssOrigin:"user"}).then((()=>{try{wc.invalidate()}catch(__e2){}}))' +
  '.catch((__e3)=>console.error("[themer] insertCSS failed",__e3))' +
  '}catch(__e){console.error("[themer] apply failed",__e)}};' +
  'var __electron=require("electron");' +
  '__electron.app.on("web-contents-created",((__ev,__wc)=>{' +
  '__wc.on("dom-ready",(()=>__apply(__wc)));' +
  '__wc.on("did-navigate",(()=>__apply(__wc)));' +
  '__wc.on("did-navigate-in-page",(()=>__apply(__wc)));' +
  '}));' +
  'if(__electron.webContents&&__electron.webContents.getAllWebContents){' +
  'for(var __wc2 of __electron.webContents.getAllWebContents()){' +
  '__wc2.on("dom-ready",(()=>__apply(__wc2)));' +
  'if(!__wc2.isLoading())__apply(__wc2);' +
  '}}' +
  '}catch(__e){}})();';

const { data, header, dataOffset } = readAsar(inPath);
const files = listFiles(header);

let targetFile = null;
for (const f of files) {
  const buf = extractFileBuffer(data, dataOffset, f);
  if (buf.includes(Buffer.from(ANCHOR, 'utf8'))) {
    targetFile = f;
    break;
  }
}
if (!targetFile) {
  throw new Error('could not find any file containing the drag-region CSS anchor; app.asar has changed shape');
}

const original = extractFileBuffer(data, dataOffset, targetFile).toString('utf8');
if (original.includes('__THEMER_THEME_BOOTSTRAP__')) {
  throw new Error(`${targetFile.path} already looks patched (marker found); refusing to double-patch`);
}
const prologue = '"use strict";';
const prologueIdx = original.indexOf(prologue);
if (prologueIdx !== 0) {
  throw new Error(`expected "use strict" prologue at offset 0 of ${targetFile.path}, found at ${prologueIdx}`);
}
const marker = '/*__THEMER_THEME_BOOTSTRAP__*/';
const patched = prologue + marker + BOOTSTRAP + original.slice(prologue.length);

console.log(`patched ${targetFile.path}: inserted web-contents-created theme bootstrap after prologue`);

const replacements = new Map([[targetFile.path, Buffer.from(patched, 'utf8')]]);

// Electron/V8 code-caches hot chunks as compiled bytecode under
// /compile-cache/<basename>.x64.jsc. A stale cache entry for our target file
// reflects the OLD source, so it must be dropped or Electron keeps running
// pre-patch bytecode instead of re-parsing our edited JS.
const basename = targetFile.path.split('/').pop();
const jscPath = `/compile-cache/${basename}.x64.jsc`;
const jscEntry = files.find((f) => f.path === jscPath);
if (jscEntry) {
  replacements.set(jscPath, Buffer.alloc(0));
  console.log(`invalidated stale V8 code cache at ${jscPath}`);
}

const rebuilt = repackWithReplacements(header, data, dataOffset, replacements);
fs.writeFileSync(outPath, rebuilt);
console.log(`wrote patched asar to ${outPath} (${rebuilt.length} bytes, was ${data.length})`);
