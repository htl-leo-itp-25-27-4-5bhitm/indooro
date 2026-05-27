import { access, readFile } from "node:fs/promises";
import { constants } from "node:fs";

const requiredAssets = [
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/index.html",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/app.js",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/core.js",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/app.css",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/editor/index.html",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/editor.js",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/editor-core.js",
  "backend/indooro_server/src/main/resources/META-INF/resources/admin/editor.css"
];

for (const asset of requiredAssets) {
  await access(asset, constants.R_OK);
}

const editorHtml = await readFile(requiredAssets[4], "utf8");
if (/cdn\.tailwindcss\.com|unpkg\.com|jsdelivr\.net/.test(editorHtml)) {
  throw new Error("Admin editor must not use runtime CDN dependencies.");
}

console.log(`Verified ${requiredAssets.length} admin assets.`);
