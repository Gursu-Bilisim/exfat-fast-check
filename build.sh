#!/usr/bin/env bash
# Builds the wrapper (static aarch64) and the installable module zip.
# Needs: zig (pip install ziglang, or a zig binary on PATH), zip.
set -euo pipefail
cd "$(dirname "$0")"
VERSION=$(sed -n 's/^version=//p' module/module.prop)
if command -v zig >/dev/null; then ZIG=(zig); else ZIG=(python3 -m ziglang); fi
"${ZIG[@]}" cc -target aarch64-linux-musl -static -Os -s \
  -o module/system/bin/fsck.exfat src/exfat-fast-check.c
mkdir -p dist
OUT="dist/exfat-fast-check-$VERSION.zip"
rm -f "$OUT"
(cd module && zip -qr -X "../$OUT" .)
sha256sum "$OUT"
