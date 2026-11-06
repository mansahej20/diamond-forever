/* Generates the app icons with no image dependencies: an astroid (four-cusped
   star) is exactly the concave sparkle from the Diamond Forever mark, and it
   has a closed-form inside test, so it rasterises cleanly at any size. */
const zlib = require("zlib");
const fs = require("fs");
const path = require("path");

function png(width, height, rgba) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (width * 4 + 1)] = 0;                               // filter: none
    rgba.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4);
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body) >>> 0);
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}
let TBL = null;
function crc32(buf) {
  if (!TBL) {
    TBL = new Int32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      TBL[n] = c;
    }
  }
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = TBL[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return c ^ -1;
}

/* |x|^(2/3) + |y|^(2/3) <= r^(2/3) — the four-cusped star */
function inStar(dx, dy, r) {
  const a = Math.pow(Math.abs(dx), 2 / 3) + Math.pow(Math.abs(dy), 2 / 3);
  return a <= Math.pow(r, 2 / 3);
}

function render(size, inset) {
  const SS = 4;                              // supersample for clean cusps
  const buf = Buffer.alloc(size * size * 4);
  const c = size / 2;
  const big = size * inset * 0.5;            // main sparkle
  const small = size * inset * 0.17;         // companion, offset like the logo
  const sx = c + size * 0.255, sy = c - size * 0.255;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let hit = 0;
      for (let oy = 0; oy < SS; oy++) {
        for (let ox = 0; ox < SS; ox++) {
          const px = x + (ox + 0.5) / SS, py = y + (oy + 0.5) / SS;
          if (inStar(px - c, py - c, big) || inStar(px - sx, py - sy, small)) hit++;
        }
      }
      const a = hit / (SS * SS);
      const i = (y * size + x) * 4;
      // white mark over the vitrine black
      buf[i] = Math.round(14 + (255 - 14) * a);
      buf[i + 1] = Math.round(14 + (255 - 14) * a);
      buf[i + 2] = Math.round(14 + (255 - 14) * a);
      buf[i + 3] = 255;
    }
  }
  return png(size, size, buf);
}

const out = path.join(__dirname, "icons");
const jobs = [
  ["icon-192.png", 192, 0.62],
  ["icon-512.png", 512, 0.62],
  ["apple-touch-icon.png", 180, 0.62],
  // maskable: iOS/Android may crop to a circle, so pull the art well inside
  ["maskable-512.png", 512, 0.44],
];
for (const [name, size, inset] of jobs) {
  fs.writeFileSync(path.join(out, name), render(size, inset));
  console.log("  " + name + "  " + size + "x" + size);
}
