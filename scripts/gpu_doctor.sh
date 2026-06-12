#!/usr/bin/env bash
set -u

STATUS=0

ok() {
  echo "OK: $*"
}

warn() {
  echo "WARN: $*" >&2
  STATUS=1
}

section() {
  echo
  echo "== $* =="
}

section "GPU hardware"
if command -v lspci >/dev/null 2>&1; then
  GPU_LINES="$(lspci | grep -Ei 'vga|3d|display|nvidia|amd|radeon|intel' || true)"
  if [ -n "$GPU_LINES" ]; then
    echo "$GPU_LINES"
  else
    warn "No GPU-like PCI device found with lspci."
  fi
else
  warn "lspci is not installed."
fi

section "NVIDIA driver"
if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi >/tmp/stt_cli_nvidia_smi.out 2>/tmp/stt_cli_nvidia_smi.err; then
    ok "nvidia-smi can communicate with the NVIDIA driver."
    sed -n '1,12p' /tmp/stt_cli_nvidia_smi.out
  else
    warn "nvidia-smi is installed but cannot communicate with the NVIDIA driver."
    sed -n '1,8p' /tmp/stt_cli_nvidia_smi.err >&2
  fi
else
  warn "nvidia-smi is not installed or not in PATH."
fi

section "CUDA build prerequisites"
if command -v nvcc >/dev/null 2>&1; then
  ok "nvcc found: $(command -v nvcc)"
  nvcc --version | sed -n '1,4p'
elif [ -n "${CUDAToolkit_ROOT:-}" ]; then
  ok "CUDAToolkit_ROOT is set: $CUDAToolkit_ROOT"
else
  warn "CUDA Toolkit not found. cargo build --features cuda will fail."
fi

if [ -x /usr/local/cuda/bin/nvcc ]; then
  ok "CUDA toolkit nvcc found: /usr/local/cuda/bin/nvcc"
else
  warn "/usr/local/cuda/bin/nvcc was not found."
fi

if lspci 2>/dev/null | grep -Eiq 'GTX 1660|TU116'; then
  ok "Detected GTX 1660/TU116; use CMAKE_CUDA_ARCHITECTURES=75 if native arch detection fails."
fi

section "Vulkan build prerequisites"
if command -v glslc >/dev/null 2>&1; then
  ok "glslc found: $(command -v glslc)"
else
  warn "glslc not found. cargo build --features vulkan will fail."
fi

if [ -f /usr/include/vulkan/vulkan.h ]; then
  ok "Vulkan headers found at /usr/include/vulkan/vulkan.h"
else
  warn "Vulkan headers not found at /usr/include/vulkan/vulkan.h."
fi

if ldconfig -p 2>/dev/null | grep -q 'libvulkan\.so'; then
  ok "libvulkan is visible to ldconfig."
else
  warn "libvulkan was not found by ldconfig."
fi

section "Suggested install commands"
echo "CPU build:"
echo "  bash scripts/install_user.sh"
echo
echo "CUDA GPU build:"
echo "  bash scripts/install_user.sh --features cuda"
echo "  # Override manually if needed:"
echo "  CUDAToolkit_ROOT=/usr/local/cuda CMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc CMAKE_CUDA_ARCHITECTURES=75 bash scripts/install_user.sh --features cuda"
echo
echo "Vulkan GPU build:"
echo "  bash scripts/install_user.sh --features vulkan"

exit "$STATUS"
