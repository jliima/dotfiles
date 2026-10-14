#!/usr/bin/env node
// Patches a pristine claude-desktop app.asar so every webContents the app
// creates insertCSS()s an external, user-writable theme file once its page
// is ready.
//
// Usage: node asar-patch.mjs <input-asar> <output-asar>
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
  console.error('usage: asar-patch.mjs <input-asar> <output-asar>');
  process.exit(2);
}

// Anchor used only to find the right file: the app's own drag-region fix,
// present in the same early-loaded bundle as its window/tab setup code.
const ANCHOR = '-webkit-app-region: no-drag !important';

// Artifacts and project documents are drawn inside cross-origin iframes (*.frame.claudeusercontent.com), which
// insertCSS() on the window cannot reach. For those frames the bootstrap evaluates a snippet that adopts a
// constructed stylesheet (not a <style> element, so the frame's CSP cannot block it) built from frame.css. When
// Documents sit one level deeper, in about:srcdoc iframes of such a frame, so those count as frames too.
// The bootstrap also switches off Chromium's Wayland color manager (washed-out dark tones under KWin), whatever
// launcher started the app (the app rewrites its own desktop entry).
// ~/.config/claude-desktop-theme/frame-debug.js exists, every frame also evaluates it (an expression returning a
// string) and appends the result to ~/.cache/claude-desktop-theme/frames.log, for working out what frame.css has to
// override.
const FRAME_SNIPPET = String.raw`(function(css){
  try {
    var old = document.adoptedStyleSheets.filter(function(s){ return !s.__themer; });
    if (css) { var sheet = new CSSStyleSheet(); sheet.__themer = true; sheet.replaceSync(css); old.push(sheet); }
    document.adoptedStyleSheets = old;
  } catch (e) {}
})`;

const BOOTSTRAP =
  '(function(){try{' +
  'var __fs=require("node:fs"),__path=require("node:path"),__home=require("node:os").homedir();' +
  'var __read=function(__n){try{return __fs.readFileSync(__path.join(__home,".config","claude-desktop-theme",__n),"utf8")}catch(__e){return null}};' +
  'var __load=function(){return __read("theme.css")};' +
  'var __apply=function(wc){' +
  'try{if(wc.isDestroyed())return;var __c=__load();if(__c==null)return;' +
  '__debug(wc,"main-debug.js");' +
  'wc.insertCSS(__c,{cssOrigin:"user"}).then((()=>{try{wc.invalidate()}catch(__e2){}}))' +
  '.catch((__e3)=>console.error("[themer] insertCSS failed",__e3))' +
  '}catch(__e){console.error("[themer] apply failed",__e)}};' +
  'var __snippet=' + FRAME_SNIPPET + ';' +
  'var __isHost=function(__u){try{return /\\.(frame\\.(staging\\.)?claudeusercontent|claudemcpcontent)\\.com$/.test(new URL(__u).hostname)}catch(__e){return false}};' +
  'var __isFrame=function(__f){while(__f){if(__isHost(__f.url))return true;if(!/^(about:(srcdoc|blank))?$/.test(__f.url))return false;__f=__f.parent}return false};' +
  'var __debug=function(__t,__n){try{var __dbg=__read(__n);if(!__dbg)return;setTimeout((()=>{try{if(__t.isDestroyed())return;' +
  '__t.executeJavaScript(__dbg).then(((__r)=>{if(__r){var __d=__path.join(__home,".cache","claude-desktop-theme");' +
  '__fs.mkdirSync(__d,{recursive:true});__fs.appendFileSync(__path.join(__d,"frames.log"),__r+"\\n")}})).catch((__e)=>{})}catch(__e){}}),4000)}catch(__e){}};' +
  'var __applyFrame=function(__f){' +
  'try{if(__f.isDestroyed()||!__isFrame(__f))return;' +
  '__f.executeJavaScript("("+__snippet+")("+JSON.stringify(__read("frame.css"))+")").catch((__e)=>console.error("[themer] frame failed",__e));' +
  '__debug(__f,"frame-debug.js");' +
  '}catch(__e){console.error("[themer] frame apply failed",__e)}};' +
  'var __watch=function(__wc){' +
  '__wc.on("dom-ready",(()=>__apply(__wc)));' +
  '__wc.on("did-navigate",(()=>__apply(__wc)));' +
  '__wc.on("did-navigate-in-page",(()=>__apply(__wc)));' +
  '__wc.on("frame-created",((__ev,__d)=>{try{__d.frame.on("dom-ready",(()=>__applyFrame(__d.frame)))}catch(__e){}}));' +
  '__wc.on("did-frame-finish-load",((__ev,__main,__pid,__rid)=>{try{if(__main)return;' +
  'var __f=require("electron").webFrameMain.fromId(__pid,__rid);if(__f)__applyFrame(__f)}catch(__e){}}));' +
  '};' +
  'var __electron=require("electron");' +
  'try{var __cl=__electron.app.commandLine,__df=__cl.getSwitchValue("disable-features");' +
  'if(!/WaylandWpColorManagerV1/.test(__df))__cl.appendSwitch("disable-features",(__df?__df+",":"")+"WaylandWpColorManagerV1")}catch(__e){}' +
  '__electron.app.on("web-contents-created",((__ev,__wc)=>__watch(__wc)));' +
  'if(__electron.webContents&&__electron.webContents.getAllWebContents){' +
  'for(var __wc2 of __electron.webContents.getAllWebContents()){' +
  '__watch(__wc2);' +
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

// The window background and the title bar overlay (the minimize/maximize/close buttons) get fixed Claude colors in the
// main process. Replace those literals with a lookup in ~/.config/claude-desktop-theme/window.json (keys light, dark,
// symbolLight, symbolDark) that falls back to the original color, so the file is optional. Read when the app starts.
const WINDOW_COLOR =
  '(function(k,d){try{return JSON.parse(require("node:fs").readFileSync(require("node:path").join(' +
  'require("node:os").homedir(),".config","claude-desktop-theme","window.json"),"utf8"))[k]||d}catch(e){return d}})';
const WINDOW_LITERALS = [
  ['{light:"#fcfcfb",dark:"#151515"}', `{light:${WINDOW_COLOR}("light","#fcfcfb"),dark:${WINDOW_COLOR}("dark","#151515")}`],
  ['"#c2c0b6"', `${WINDOW_COLOR}("symbolDark","#c2c0b6")`],
  ['"#3d3d3a"', `${WINDOW_COLOR}("symbolLight","#3d3d3a")`],
];
const patchedFiles = new Set([targetFile.path]);
for (const f of files) {
  if (!f.path.startsWith('/.vite/build/') || !f.path.endsWith('.js')) continue;
  let text = (replacements.get(f.path) ?? extractFileBuffer(data, dataOffset, f)).toString('utf8');
  if (!text.includes(WINDOW_LITERALS[0][0])) continue;
  for (const [from, to] of WINDOW_LITERALS) {
    if (!text.includes(from)) throw new Error(`${f.path}: window color ${from} not found; app.asar has changed shape`);
    text = text.split(from).join(to);
  }
  replacements.set(f.path, Buffer.from(text, 'utf8'));
  patchedFiles.add(f.path);
  console.log(`patched ${f.path}: window and title bar colors read from window.json`);
}

// Electron/V8 code-caches hot chunks as compiled bytecode under
// /compile-cache/<basename>.x64.jsc. A stale cache entry for a patched file
// reflects the OLD source, so it must be dropped or Electron keeps running
// pre-patch bytecode instead of re-parsing our edited JS.
for (const path of patchedFiles) {
  const jscPath = `/compile-cache/${path.split('/').pop()}.x64.jsc`;
  if (files.some((f) => f.path === jscPath)) {
    replacements.set(jscPath, Buffer.alloc(0));
    console.log(`invalidated stale V8 code cache at ${jscPath}`);
  }
}

const rebuilt = repackWithReplacements(header, data, dataOffset, replacements);
fs.writeFileSync(outPath, rebuilt);
console.log(`wrote patched asar to ${outPath} (${rebuilt.length} bytes, was ${data.length})`);
