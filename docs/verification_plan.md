# Verification Plan

## Goals

Verify the supported 2-master / 2-target AXI4-Lite subset: address arbitration, independent AW/W handshakes, write ownership, response routing, read routing, byte strobes, and concurrent requests.

## Existing RTL regression

The self-checking testbench is `tb/tb_axi_lite_2x2_interconnect.sv`. It contains two simple target memory models and checks transaction outcomes using tasks that time out if a handshake does not complete.

| ID | Scenario | Status in RTL regression | Check |
|---|---|---|---|
| RTL-01 | Master 0 accesses target 0 | Implemented | Readback matches written word |
| RTL-02 | Master 1 accesses target 1 | Implemented | Readback matches written word |
| RTL-03 | Partial byte write | Implemented | Untouched bytes remain unchanged |
| RTL-04 | Concurrent writes to different targets | Implemented | Both transactions complete and read back correctly |
| RTL-05 | Two masters contend for target 0 writes | Implemented | Both writes complete and read back correctly |
| RTL-06 | Simultaneous read requests to target 0 | Implemented | Both masters receive their expected data |
| RTL-07 | AXI channel stability while stalled | Assertions instantiated | Verilator assertion-enabled regression |
| RTL-08 | Randomized response latency/backpressure | Not yet implemented | Add randomized target stalls |
| RTL-09 | Reset during outstanding work | Not yet implemented | Define reset contract and test it |
| RTL-10 | Deliberate fault injection | Not yet implemented | Demonstrate checker sensitivity |

## UVM environment

`tb/uvm/` contains transaction items, two master agents with drivers and monitors, a test environment, directed transactions, a constrained-random phase of 20 transactions per master, target models, a reference-memory scoreboard, and transaction covergroups. The UVM driver also deliberately holds BREADY/RREADY low for two clock edges to exercise response stability while stalled. Random transactions use disjoint word-index ranges per master to avoid artificial cross-master data races. Run the UVM test using Cadence Xcelium via `SEED=42 bash scripts/run_xcelium_uvm.sh` on a licensed environment. The seed is passed to Xcelium and logged for reproducibility. A UVM result is not considered validated until the simulator run completes and the scoreboard summary is reviewed.

## Checker principles

- The RTL smoke test compares read data with expected values and checks responses/timeouts.
- The protocol assertion module checks that AXI-Lite VALID and payload remain stable when READY is low.
- The UVM scoreboard models memory independently from DUT internal state and compares observed reads with its expected contents.
- Failure messages should include master, address, expected/observed data, and response code where applicable.

## Reproducible evidence

Run locally with `bash scripts/run_verilator_smoke.sh`. CI executes the same script and uploads `results/verilator_smoke.log` and `results/axi_lite_smoke.vcd` as the `axi-lite-smoke-evidence` artifact. Keep the run URL, commit SHA, simulator version, and test summary when presenting results.

## Exit criteria for future milestones

1. Directed tests pass on the selected simulator.
2. Randomized latency and backpressure tests are added with reproducible seeds.
3. Reset and error behavior are specified and tested.
4. UVM scoreboard errors equal zero in a completed Xcelium run.
5. Functional coverage is reported from an actual UVM run; uncovered bins are reviewed.
6. At least one injected defect is detected by the intended checker and documented.
