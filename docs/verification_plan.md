# Verification Plan

## Goals

Verify routing, arbitration, channel handshakes, response association, reset recovery, and error behavior against a frozen design specification. The reference model must be independent of the DUT implementation.

## Planned environment components

- **Sequence item:** Describes a read/write transaction, address, burst attributes, and write data.
- **Sequences:** Directed scenarios and constrained-random traffic.
- **Driver:** Drives the interface according to the supported AXI protocol.
- **Monitor:** Observes accepted requests and responses without driving the DUT.
- **Target model:** Accepts requests and generates delayed responses and optional errors.
- **Reference model:** Predicts expected routing and transaction outcomes without relying on DUT internal state.
- **Scoreboard:** Matches observed transactions to expected outcomes and reports data corruption, loss, duplication, or misrouting.
- **Assertions:** Check protocol behavior and design invariants.
- **Coverage collector:** Samples completed behavior and meaningful crosses.
- **Regression runner:** Executes tests with reproducible random seeds and aggregates results.

## Test scenario matrix

| ID | Scenario | Expected checks |
|---|---|---|
| V01 | Reset smoke | Clean documented idle state; no spurious response |
| V02 | Single-master read | Correct target decode and returned data |
| V03 | Single-master write | Correct destination and write response |
| V04 | Concurrent requests to different targets | Independent progress where supported |
| V05 | Both masters contend for one target | Legal arbitration; loser remains handled correctly |
| V06 | Concurrent read and write traffic | Independent channel behavior as specified |
| V07 | Target backpressure | No dropped/duplicated accepted transaction |
| V08 | Different target response delays | Correct response/master/ID association |
| V09 | Address-map boundaries | Correct target selection or documented error |
| V10 | Burst tests | Correct supported burst, length, size, and boundary behavior |
| V11 | Multiple outstanding traffic | Correct matching and ordering, if supported |
| V12 | Target error response | Correct error propagation and recovery |
| V13 | Reset during active traffic | Behavior conforms to reset contract; no stale misrouting |
| V14 | Constrained-random mixed traffic | Scoreboard consistency; coverage collected |
| V15 | Fault injection | Named checker detects each deliberate defect |

## Checker design principles

- Compare at observable interface boundaries.
- Match responses only using fields and ordering guarantees defined by the supported spec.
- Avoid over-constraining legal AXI behavior.
- Include seed, simulation time, master, target, transaction ID (if present), address, expected value, and observed value in mismatch reports.
- Explicitly define treatment of accepted but incomplete work during reset.

## Exit criteria

A milestone is complete when the relevant tests compile and run, expected-pass tests pass, deliberate negative tests fail for the intended reason, assertion failures are explained, coverage holes are reviewed, and simulator/version/seed/limitations are documented. Numeric coverage goals will be set only after actual covergroups and reports exist.