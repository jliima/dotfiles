// Minimal Electron asar (un)packer: no npm/asar CLI is available on this
// machine, just a bare `node` binary, so this reimplements the format
// directly (two nested Chromium Pickles for the header, then the
// concatenated file data). Round-trip-tested to be byte-identical against
// claude-desktop's app.asar before this was trusted for real edits.
import fs from 'node:fs';
import crypto from 'node:crypto';

export function readAsar(archivePath) {
  const data = fs.readFileSync(archivePath);
  const headerPickleSize = data.readUInt32LE(4);
  const headerPickleBuf = data.subarray(8, 8 + headerPickleSize);
  const strLen = headerPickleBuf.readUInt32LE(4);
  const jsonStr = headerPickleBuf.subarray(8, 8 + strLen).toString('utf8');
  const header = JSON.parse(jsonStr);
  const dataOffset = 8 + headerPickleSize;
  return { data, header, dataOffset };
}

// Walk the header tree, returning [{path, node, offset, size}] for leaf (non-unpacked) file entries,
// sorted by offset ascending. `node` is a live reference into `header` for in-place mutation.
export function listFiles(header) {
  const out = [];
  function walk(tree, prefix) {
    for (const [name, entry] of Object.entries(tree.files || {})) {
      const p = prefix + '/' + name;
      if (entry.files) {
        walk(entry, p);
      } else if (entry.offset !== undefined) {
        out.push({ path: p, node: entry, offset: parseInt(entry.offset, 10), size: entry.size });
      }
    }
  }
  walk(header, '');
  out.sort((a, b) => a.offset - b.offset);
  return out;
}

export function extractFileBuffer(data, dataOffset, fileEntry) {
  return data.subarray(dataOffset + fileEntry.offset, dataOffset + fileEntry.offset + fileEntry.size);
}

function pickleString(str) {
  const strBuf = Buffer.from(str, 'utf8');
  const padLen = (4 - (strBuf.length % 4)) % 4;
  const payload = Buffer.concat([
    uint32LE(strBuf.length),
    strBuf,
    Buffer.alloc(padLen),
  ]);
  return Buffer.concat([uint32LE(payload.length), payload]);
}

function uint32LE(n) {
  const b = Buffer.alloc(4);
  b.writeUInt32LE(n, 0);
  return b;
}

function computeIntegrity(buf) {
  const blockSize = 4 * 1024 * 1024;
  const blocks = [];
  for (let off = 0; off < buf.length; off += blockSize) {
    const block = buf.subarray(off, Math.min(off + blockSize, buf.length));
    blocks.push(crypto.createHash('sha256').update(block).digest('hex'));
  }
  if (buf.length === 0) {
    blocks.push(crypto.createHash('sha256').update(Buffer.alloc(0)).digest('hex'));
  }
  const hash = crypto.createHash('sha256').update(buf).digest('hex');
  return { algorithm: 'SHA256', hash, blockSize, blocks };
}

// Rebuild an asar buffer from a header object (with leaf nodes' size/offset/integrity already
// updated to match `buffers`) and the ordered list of {path, buf} matching that same order.
export function buildAsar(header, orderedBuffers) {
  const dataBuf = Buffer.concat(orderedBuffers.map((f) => f.buf));
  const headerPickle = pickleString(JSON.stringify(header));
  const outer = Buffer.concat([uint32LE(4), uint32LE(headerPickle.length)]);
  return Buffer.concat([outer, headerPickle, dataBuf]);
}

// Given the parsed header/file list/data, apply content replacements (map of path -> newBuffer),
// recompute offsets/sizes/integrity in place, and return the new full asar Buffer.
//
// asar deduplicates byte-identical files: several tree entries can share the same
// original offset/size (e.g. the same font copied into every renderer bundle). Those
// must be grouped and re-offset together, or the rebuilt archive balloons and the
// duplicated ranges collide with real data.
export function repackWithReplacements(header, data, dataOffset, replacements) {
  const files = listFiles(header);

  const groups = new Map(); // original offset -> { size, nodes: [], buf }
  for (const f of files) {
    let g = groups.get(f.offset);
    if (!g) {
      g = { size: f.size, nodes: [], paths: [] };
      groups.set(f.offset, g);
    }
    if (g.size !== f.size) {
      throw new Error(`offset ${f.offset} has mismatched sizes across entries (${g.size} vs ${f.size})`);
    }
    g.nodes.push(f.node);
    g.paths.push(f.path);
  }

  const orderedOffsets = [...groups.keys()].sort((a, b) => a - b);
  let cursor = 0;
  const ordered = [];
  for (const off of orderedOffsets) {
    const g = groups.get(off);
    const replacedPath = g.paths.find((p) => replacements.has(p));
    const buf = replacedPath !== undefined
      ? replacements.get(replacedPath)
      : data.subarray(dataOffset + off, dataOffset + off + g.size);
    const integrity = g.nodes[0].integrity ? computeIntegrity(buf) : undefined;
    for (const node of g.nodes) {
      node.offset = String(cursor);
      node.size = buf.length;
      if (integrity) node.integrity = integrity;
    }
    cursor += buf.length;
    ordered.push({ paths: g.paths, buf });
  }
  return buildAsar(header, ordered);
}
