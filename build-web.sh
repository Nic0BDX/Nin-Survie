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
unzip -j -q "$tools/templates.zip" templates/web_nothreads_release.zip -d "$templates"
"$editor" --headless --path . --import
"$editor" --headless --path . --export-release Web dist/index.html
node web-host.mjs
test -s dist/index.wasm
test -s dist/index.pck
