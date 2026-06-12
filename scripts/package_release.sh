#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building release..."
cargo build --release

BIN="$ROOT/target/release/stt_cli"
if [ ! -f "$BIN" ]; then
  echo "Binary not found at $BIN"
  exit 1
fi

PKG_DIR="$ROOT/dist"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"

TMP="$PKG_DIR/stt_cli_bundle"
rm -rf "$TMP"
mkdir -p "$TMP"

cp "$BIN" "$TMP/" || true
cp README.md "$TMP/" || true
cp docs/USAGE.md "$TMP/" || true
cp Cargo.toml "$TMP/" || true
cp LICENSE "$TMP/" || true
mkdir -p "$TMP/scripts"
cp scripts/install_user.sh "$TMP/scripts/" || true
cp scripts/gpu_doctor.sh "$TMP/scripts/" || true

chmod +x "$TMP/stt_cli" || true
chmod +x "$TMP/scripts/install_user.sh" || true
chmod +x "$TMP/scripts/gpu_doctor.sh" || true

ARCHIVE_NAME="stt_cli-linux.tar.gz"
tar -C "$TMP" -czf "$PKG_DIR/$ARCHIVE_NAME" .

echo "Package created: $PKG_DIR/$ARCHIVE_NAME"
