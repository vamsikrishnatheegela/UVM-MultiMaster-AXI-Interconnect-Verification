# RTL

The synthesizable interconnect RTL will be added after the supported AXI subset and arbitration/reset semantics are frozen.

Planned modules:
- Address decoder
- Per-target request arbiter
- Request router
- Read/write response router
- Top-level 2-master / 2-target interconnect

Implementation rules:
- Do not claim full AXI compliance unless supported features are implemented and verified.
- Keep arbitration policy and address map documented.
- Add unit-level checks before integrating the full interconnect.