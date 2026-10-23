#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p results

if ! command -v xrun >/dev/null 2>&1; then
  echo "ERROR: xrun was not found. This script requires Cadence Xcelium with UVM support." >&2
  exit 127
fi

xrun -64bit -uvm -sv -timescale 1ns/1ps \
  -f tb/uvm/axi_lite_uvm.f \
  -top tb_axi_lite_uvm \
  -access +rwc \
  -l results/xcelium_uvm.log

if grep -q "SB_READ_MISMATCH" results/xcelium_uvm.log; then
  echo "FAIL: UVM scoreboard reported a read mismatch." >&2
  exit 1
fi

grep -q "SB_SUMMARY" results/xcelium_uvm.log
echo "UVM run completed. Review results/xcelium_uvm.log for scoreboard summary."
