# UVM Testbench

Planned structure:

- `interfaces/`: AXI interface, clocking blocks, and modports.
- `agents/`: reusable master agents, monitors, and target-side components.
- `env/`: environment configuration and virtual sequencer.
- `sequences/`: directed and constrained-random sequences.
- `tests/`: test classes and scenario selection.
- `assertions/`: protocol properties and design-specific invariants.
- `scoreboard/`: transaction matching, reference model, and diagnostics.

The exact class hierarchy and configuration approach will be chosen after the supported AXI feature set and simulator are selected. Component status will be updated as code is added and tested.