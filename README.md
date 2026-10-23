# UVM-Based Multi-Master AXI Interconnect Verification

A coverage-driven SystemVerilog/UVM project to verify a small multi-master AXI interconnect, emphasizing concurrent traffic, arbitration, request/response routing, backpressure, transaction integrity, and reset recovery.

> **Status:** Initial project scaffold. RTL, UVM components, tests, and coverage metrics will be marked complete only after implementation and simulation.

## Objectives

- Specify a manageable AXI4 subset for a 2-master / 2-target interconnect.
- Exercise concurrent read/write traffic and competing requests.
- Check address decode, arbitration, response routing, and transaction integrity.
- Build reusable UVM agents, monitors, sequences, a reference model, and scoreboard.
- Add assertions, functional coverage, and reproducible regression tests.
- Document known limitations and real results without inventing coverage or pass-rate claims.

## Planned topology

Two independent AXI masters connect through an interconnect to two memory-mapped targets. The interconnect contains address decode, arbitration, request routing, and response routing. Target models will support independently configurable latency and response behavior.

## Planned repository layout

```text
.
├── README.md
├── docs/
│   ├── architecture.md
│   ├── verification_plan.md
│   └── coverage_plan.md
├── rtl/
├── tb/
│   ├── interfaces/
│   ├── agents/
│   ├── env/
│   ├── sequences/
│   ├── tests/
│   ├── assertions/
│   └── scoreboard/
├── sim/
└── scripts/
```

## Planned high-value scenarios

- Both masters request the same target concurrently.
- Masters access different targets at the same time.
- Independent backpressure on read/write channels.
- Variable target response delays.
- Address-map boundaries and unmapped addresses.
- Burst length/boundary cases for the supported subset.
- Multiple outstanding requests and ID matching, if supported.
- Reset during idle, active transfer, and delayed response.
- Error response propagation and recovery.
- Constrained-random traffic with reproducible seeds.
- Deliberate defects injected into separate RTL variants to validate checkers.

## Implementation roadmap

1. Freeze the AXI profile, widths, address map, burst/ID/outstanding behavior, arbitration policy, and reset contract.
2. Implement and lint synthesizable RTL.
3. Add target models and directed smoke tests.
4. Build UVM agents, monitors, sequences, reference model, and scoreboard.
5. Add protocol assertions and functional coverage.
6. Run directed and constrained-random regressions; record simulator/version/seeds.
7. Perform fault injection and document detected defects.

## Tools

SystemVerilog and UVM with a simulator supporting the selected UVM release (for example, Cadence Xcelium where available). Exact compile/run commands will be added after validation against the chosen simulator.

## Current status

- [x] Repository and initial project plan
- [ ] Detailed AXI subset specification
- [ ] Interconnect RTL and target models
- [ ] UVM environment and reusable agents
- [ ] Reference model and scoreboard
- [ ] Assertions and functional coverage
- [ ] Simulator-validated regression
- [ ] Fault-injection report

**No simulation results or coverage percentages are claimed yet.**
