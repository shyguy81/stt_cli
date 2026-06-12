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

check_gpu_prereqs() {
  if [[ "$FEATURES" == *cuda* ]]; then
    if [ -z "${CUDAToolkit_ROOT:-}" ] && [ -d /usr/local/cuda ]; then
      export CUDAToolkit_ROOT=/usr/local/cuda
    fi

    if [ -z "${CMAKE_CUDA_COMPILER:-}" ] && [ -x "${CUDAToolkit_ROOT:-}/bin/nvcc" ]; then
      export CMAKE_CUDA_COMPILER="$CUDAToolkit_ROOT/bin/nvcc"
    fi

    if [ -z "${CMAKE_CUDA_ARCHITECTURES:-}" ] && command -v lspci >/dev/null 2>&1; then
      if lspci | grep -Eiq 'GTX 1660|TU116'; then
        export CMAKE_CUDA_ARCHITECTURES=75
      fi
    fi

    if ! command -v nvcc >/dev/null 2>&1 && [ -z "${CUDAToolkit_ROOT:-}" ]; then
      echo "CUDA feature requested, but CUDA Toolkit was not found." >&2
      echo "Install the CUDA Toolkit so nvcc is available, or set CUDAToolkit_ROOT." >&2
      echo "Run scripts/gpu_doctor.sh for a local GPU diagnostic." >&2
      exit 1
    fi

    if [ -z "${CMAKE_CUDA_HOST_COMPILER:-}" ] && command -v nvcc >/dev/null 2>&1; then
      NVCC_VERSION="$(nvcc --version | sed -n 's/.*release \([0-9][0-9]*\).*/\1/p' | head -n 1)"
      if [ "${NVCC_VERSION:-0}" -le 12 ] && command -v clang-14 >/dev/null 2>&1; then
        export CMAKE_CUDA_HOST_COMPILER="$(command -v clang-14)"
      fi
    fi

    echo "CUDA build configuration:"
    echo "  CUDAToolkit_ROOT=${CUDAToolkit_ROOT:-<unset>}"
    echo "  CMAKE_CUDA_COMPILER=${CMAKE_CUDA_COMPILER:-<unset>}"
    echo "  CMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURES:-<unset>}"
    echo "  CMAKE_CUDA_HOST_COMPILER=${CMAKE_CUDA_HOST_COMPILER:-<unset>}"
  fi

  if [[ "$FEATURES" == *vulkan* ]]; then
    if ! command -v glslc >/dev/null 2>&1; then
      echo "Vulkan feature requested, but glslc was not found." >&2
      echo "Install Vulkan SDK/tools, then run scripts/gpu_doctor.sh again." >&2
      exit 1
    fi

    if [ ! -f /usr/include/vulkan/vulkan.h ]; then
      echo "Vulkan feature requested, but Vulkan headers were not found." >&2
      echo "Install Vulkan development headers, then run scripts/gpu_doctor.sh again." >&2
      exit 1
    fi
  fi
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
  check_gpu_prereqs

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
