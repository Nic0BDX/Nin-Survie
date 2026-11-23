#!/usr/bin/env bash
set -euo pipefail

version=4.7.2
release="${version}-stable"
downloads="https://github.com/godotengine/godot-builds/releases/download/${release}"
tools="$(mktemp -d)"
trap 'rm -rf "$tools"' EXIT

curl --fail --silent --show-error --location --retry 3 "$downloads/Godot_v${release}_linux.x86_64.zip" -o "$tools/editor.zip"
curl --fail --silent --show-error --location --retry 3 "$downloads/Godot_v${release}_export_templates.tpz" -o "$tools/templates.zip"
unzip -q "$tools/editor.zip" -d "$tools"
editor="$tools/Godot_v${release}_linux.x86_64"
chmod +x "$editor"
export XDG_DATA_HOME="$tools/data"
templates="$XDG_DATA_HOME/godot/export_templates/${version}.stable"
mkdir -p "$templates" dist
unzip -j -q "$tools/templates.zip" templates/web_nothreads_debug.zip templates/web_nothreads_release.zip -d "$templates"
"$editor" --headless --path . --import
if [[ "${NIN_VERIFY:-0}" == world || "${NIN_VERIFY:-0}" == art ]]; then
  "$editor" --headless --path . --script studio/check_world.gd -- --qa 2>&1 | tee "$tools/world.log"
  if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR' "$tools/world.log"; then exit 1; fi
fi
"$editor" --headless --path . --export-release Web dist/index.html
node web-host.mjs
test -s dist/index.wasm
test -s dist/index.pck

if [[ "${NIN_VERIFY:-0}" == story ]]; then
  npm install --prefix story_authoring --no-fund --no-audit
  npm run --prefix story_authoring typecheck
  npm run --prefix story_authoring validate
fi

if [[ "${NIN_VERIFY:-0}" == 1 || "${NIN_VERIFY:-0}" == viewport || "${NIN_VERIFY:-0}" == story || "${NIN_VERIFY:-0}" == art ]]; then
  npm install --prefix "$tools/browser" --no-fund --no-audit @sparticuz/chromium@140.0.0 puppeteer-core@24.20.0
  node verify-web.mjs "$tools/browser"
fi
