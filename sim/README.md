# Simulation

Tool-specific compile/run commands will be added only after validation against the available simulator and UVM release.

Intended flow:
1. Compile RTL and interface definitions.
2. Compile UVM package and testbench.
3. Run directed smoke tests.
4. Enable protocol and design assertions.
5. Run directed corner-case tests.
6. Run constrained-random regressions with recorded seeds.
7. Archive logs and coverage reports.

A successful compile alone is not evidence of functional correctness.