# Validation and Simulation Evidence

## RTL smoke regression

A GitHub Actions run completed successfully for the self-checking Verilator regression:

- **Workflow run:** [Run #27 — RTL Smoke Regression](https://github.com/vamsikrishnatheegela/UVM-MultiMaster-AXI-Interconnect-Verification/actions/runs/39967283253)
- **Commit tested:** `b89fc63be0b2a676a8b674752ebc1d8527c5b4ed`
- **Result:** Success
- **Simulator:** Verilator with `--binary --timing --trace --assert`
- **Artifact:** [Download simulation log and VCD waveform](https://github.com/vamsikrishnatheegela/UVM-MultiMaster-AXI-Interconnect-Verification/actions/runs/39967283253/artifacts/12507900938)

### Observed test output

The regression reported successful readback for:

- Master 0, target 0: `0x11223344`
- Master 1, target 1: `0xA5C35A3C`
- Partial-strobe update: `0x1122CCDD`
- Concurrent target accesses: `0x0BADF00D` and `0xC001D00D`
- Same-target write contention: `0xCAFE0001` and `0xCAFE0002`
- Same-target read contention: both expected values returned to the correct masters

The run ended with:

```text
ALL TESTS PASSED: AXI4-Lite 2x2 smoke regression
PASS: Smoke regression completed. Log: results/verilator_smoke.log
```

The artifact contains the complete simulator log and VCD waveform, which can be opened in GTKWave or another VCD viewer.

## Scope of this evidence

This evidence validates the **directed RTL smoke regression** on the commit above. It does not establish full AXI4 compliance, exhaustive correctness, functional coverage closure, or a successful proprietary-simulator UVM run.

The RTL and testbench have since received small warning-cleanup edits. A fresh workflow run for the latest commit should be checked before treating the current HEAD as validated.

## UVM status

The repository contains a UVM environment with two master agents, a driver/monitor path, directed sequences, target models, scoreboard, and transaction covergroups. The Xcelium UVM test must be run in an environment with a compatible Cadence Xcelium/UVM installation. No UVM coverage percentage is claimed until a real run produces a report.
