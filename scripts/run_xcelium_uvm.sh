#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p results
SEED="${SEED:-1}"
echo "UVM random seed: ${SEED}"

if ! command -v xrun >/dev/null 2>&1; then
  echo "ERROR: xrun was not found. This script requires Cadence Xcelium with UVM support." >&2
  exit 127
fi

xrun -64bit -uvm -sv -timescale 1ns/1ps \
  -f tb/uvm/axi_lite_uvm.f \
  -top tb_axi_lite_uvm \
  -access +rwc \
  -l results/xcelium_uvm.log

if grep -Eq "SB_READ_MISMATCH|SCOREBOARD_RESP|SB_FAIL|UVM_FATAL" results/xcelium_uvm.log; then
  echo "FAIL: UVM fatal or scoreboard error marker found in results/xcelium_uvm.log." >&2
  exit 1
fi

grep -Eq "SB_SUMMARY.*Scoreboard errors=0" results/xcelium_uvm.log
grep -q "COVERAGE" results/xcelium_uvm.log
echo "PASS: UVM run completed with zero scoreboard errors. Review results/xcelium_uvm.log for counts and coverage."
