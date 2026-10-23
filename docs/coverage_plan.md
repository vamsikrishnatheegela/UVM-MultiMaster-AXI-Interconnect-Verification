# Functional Coverage Plan

## Current implementation

The UVM scoreboard in `tb/uvm/axi_lite_scoreboard.svh` defines transaction coverpoints for:

- Read versus write.
- Target 0 versus target 1.
- Master 0 versus master 1.
- OKAY versus non-OKAY response.
- Transaction kind crossed with target.
- Master crossed with target.

These covergroups are defined in source. A numerical coverage result must only be reported after a successful UVM simulation with a simulator that supports the covergroup implementation.

## Recommended expansion

### Arbitration and concurrency
- Both masters requesting the same target in overlapping cycles.
- Both masters accessing different targets concurrently.
- Which master wins each contention event.
- Repeated contention sequences to check round-robin progress.

### Timing and backpressure
- Immediate handshake, short stall, and multi-cycle stall on AW/W/B/AR/R.
- Independently delayed target responses.
- Response backpressure while VALID is held high.

### Write behavior
- AW before W and W held until the address is accepted.
- Byte-strobe combinations: all lanes, individual lanes, and partial masks.
- Response routing after delayed W/B phases.

### Read behavior
- Concurrent AR requests to one target.
- Reads to both targets concurrently.
- R response backpressure and stable response payload.

### Reset and errors
- Reset while idle and while a transaction is outstanding.
- Error response propagation if error injection is added to target models.

## Coverage closure process

1. Run the UVM test and save the simulator coverage report.
2. Review uncovered bins and determine whether they represent missing stimulus, unreachable behavior, or an issue in the spec/design.
3. Add directed sequences or refine random constraints.
4. Document justified exclusions.
5. Re-run and preserve the coverage report alongside the seed and simulator version.

Functional coverage is a measure of exercised scenarios, not proof that the design is bug-free. Code coverage and functional coverage should be reviewed together where the simulator supports both.
