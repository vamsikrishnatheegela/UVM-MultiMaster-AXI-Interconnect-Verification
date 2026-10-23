#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
echo "[INFO] Simulator: $(iverilog -V 2>&1 | head -n 1)"
iverilog -g2012 -Wall -s axi_lite_2x2_smoke_tb \
  -o build/axi_lite_2x2_smoke.vvp \
  rtl/axi_lite_2x2_interconnect.sv tb/axi_lite_2x2_smoke_tb.sv
vvp build/axi_lite_2x2_smoke.vvp | tee build/simulation.log
grep -q "PASS: AXI-Lite 2x2 smoke test" build/simulation.log
grep -q "PROOF: AW=4 AR=4 B=4 R=4" build/simulation.log
echo "[PASS] Smoke simulation and log checks passed."
