#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const representations = [
  { type: "icp4", pixels: 16 },
  { type: "icp5", pixels: 32 },
  { type: "icp6", pixels: 64 },
  { type: "ic07", pixels: 128 },
  { type: "ic08", pixels: 256 },
  { type: "ic09", pixels: 512 },
  { type: "ic10", pixels: 1024 },
];

function stop(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

const [, , sourcePath, outputPath] = process.argv;
if (!sourcePath || !outputPath) {
  stop("Usage: node scripts/build-app-icon.js SOURCE.png OUTPUT.icns");
}
if (!fs.existsSync(sourcePath)) {
  stop(`The app icon source does not exist: ${sourcePath}`);
}

const properties = execFileSync(
  "/usr/bin/sips",
  ["-g", "pixelWidth", "-g", "pixelHeight", sourcePath],
  { encoding: "utf8" }
);
const width = Number(properties.match(/pixelWidth: (\d+)/)?.[1]);
const height = Number(properties.match(/pixelHeight: (\d+)/)?.[1]);
if (!width || width !== height) {
  stop(`The app icon source must be square: ${sourcePath}`);
}

const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "geoffrey-icon-"));
try {
  const chunks = representations.map(({ type, pixels }) => {
    const pngPath = path.join(temporaryDirectory, `${pixels}.png`);
    execFileSync(
      "/usr/bin/sips",
      ["-z", String(pixels), String(pixels), sourcePath, "--out", pngPath],
      { stdio: "ignore" }
    );
    const png = fs.readFileSync(pngPath);
    const header = Buffer.alloc(8);
    header.write(type, 0, 4, "ascii");
    header.writeUInt32BE(header.length + png.length, 4);
    return Buffer.concat([header, png]);
  });

  const body = Buffer.concat(chunks);
  const header = Buffer.alloc(8);
  header.write("icns", 0, 4, "ascii");
  header.writeUInt32BE(header.length + body.length, 4);

  const stagedPath = `${outputPath}.building`;
  fs.writeFileSync(stagedPath, Buffer.concat([header, body]));
  fs.renameSync(stagedPath, outputPath);
  process.stdout.write(`Built ${outputPath} from ${sourcePath}.\n`);
} finally {
  fs.rmSync(temporaryDirectory, { recursive: true, force: true });
}
