#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${STT_CLI_BIN_DIR:-$HOME/.local/bin}"
FEATURES="${STT_CLI_FEATURES:-}"
BUILD=true

usage() {
  cat <<'EOF'
Usage: scripts/install_user.sh [OPTIONS]

Build and install stt_cli for the current user.

Options:
  --bin-dir <path>     Install directory (default: $HOME/.local/bin)
  --features <list>    Cargo features to enable, for example: cuda
  --no-build           Install an existing target/release/stt_cli
  -h, --help           Show this help

Environment:
  STT_CLI_BIN_DIR      Default install directory override
  STT_CLI_FEATURES     Default Cargo features override
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for --bin-dir" >&2
        exit 2
      fi
      BIN_DIR="$2"
      shift 2
      ;;
    --features)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for --features" >&2
        exit 2
      fi
      FEATURES="$2"
      shift 2
      ;;
    --no-build)
      BUILD=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$ROOT"

if [ "$BUILD" = true ]; then
  if [ -n "$FEATURES" ]; then
    cargo build --release --features "$FEATURES"
  else
    cargo build --release
  fi
fi

BIN="$ROOT/target/release/stt_cli"
if [ ! -f "$BIN" ]; then
  echo "Binary not found at $BIN" >&2
  echo "Run without --no-build or build it first with cargo build --release." >&2
  exit 1
fi

mkdir -p "$BIN_DIR"
install -m 0755 "$BIN" "$BIN_DIR/stt_cli"

echo "Installed stt_cli to $BIN_DIR/stt_cli"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "Warning: $BIN_DIR is not in PATH." >&2
    echo "Add this to your shell profile: export PATH=\"$BIN_DIR:\$PATH\"" >&2
    ;;
esac
