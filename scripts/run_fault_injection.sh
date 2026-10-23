#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v verilator >/dev/null 2>&1 || {
  echo "ERROR: Verilator is required for the fault-injection experiment." >&2
  exit 127
}

mkdir -p build/fault_injection results
FAULT_RTL="build/fault_injection/axi_lite_2x2_interconnect_faulty.sv"
cp rtl/axi_lite_2x2_interconnect.sv "$FAULT_RTL"

# Inject a single-bit read-data corruption only into a temporary build copy.
python3 - "$FAULT_RTL" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
needle = "m_rdata[0]  = s_rdata[t];"
replacement = "m_rdata[0]  = s_rdata[t] ^ 32'h00000001;"
if source.count(needle) != 1:
    raise SystemExit(f"Expected exactly one injection point, found {source.count(needle)}")
path.write_text(source.replace(needle, replacement))
print("[INJECT] Flipped bit 0 of read data routed to master 0 (temporary copy only).")
PY

verilator --binary --timing --trace --assert \
  --top-module tb_axi_lite_2x2_interconnect \
  -Wall -Wno-fatal \
  --Mdir build/fault_injection/obj_dir \
  "$FAULT_RTL" \
  tb/assertions/axi_lite_channel_assertions.sv \
  tb/tb_axi_lite_2x2_interconnect.sv

set +e
./build/fault_injection/obj_dir/Vtb_axi_lite_2x2_interconnect +TRACE > results/fault_injection.log 2>&1
sim_status=$?
set -e

if [[ $sim_status -eq 0 ]]; then
  echo "FAIL: Faulty RTL unexpectedly passed." >&2
  cat results/fault_injection.log >&2
  exit 1
fi

if ! grep -q "READ DATA MISMATCH" results/fault_injection.log; then
  echo "FAIL: Simulation failed, but not due to the expected read-data checker." >&2
  cat results/fault_injection.log >&2
  exit 1
fi

echo "PASS: Testbench detected the injected read-data corruption."
