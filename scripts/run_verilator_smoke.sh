#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: Verilator was not found in PATH." >&2
  echo "Install Verilator 5.x or use the GitHub Actions smoke workflow." >&2
  exit 127
fi

mkdir -p results
rm -rf build/verilator
mkdir -p build/verilator

{
  echo "=== Simulator ==="
  verilator --version
  echo "=== Compile ==="
  verilator --binary --timing --trace --assert \
    --top-module tb_axi_lite_2x2_interconnect \
    -Wall -Wno-fatal \
    --Mdir build/verilator \
    rtl/axi_lite_2x2_interconnect.sv \
    tb/assertions/axi_lite_channel_assertions.sv \
    tb/tb_axi_lite_2x2_interconnect.sv
  echo "=== Run ==="
  ./build/verilator/Vtb_axi_lite_2x2_interconnect +TRACE
} 2>&1 | tee results/verilator_smoke.log

grep -q "ALL TESTS PASSED" results/verilator_smoke.log
echo "PASS: Smoke regression completed. Log: results/verilator_smoke.log"
