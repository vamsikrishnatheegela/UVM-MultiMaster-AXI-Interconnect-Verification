# Architecture and Design Scope

## Purpose

The DUT is a 2-master / 2-target AXI4-Lite interconnect implemented in `rtl/axi_lite_2x2_interconnect.sv`. It is a focused verification project for arbitration, independent AXI-Lite channels, response routing, and concurrent traffic.

## Interface and supported subset

- AXI4-Lite read and write channels.
- Default 8-bit address and 32-bit data widths, configurable through parameters.
- Byte write strobes.
- No AXI4 bursts or transaction IDs.
- One outstanding read and one outstanding write per master.
- One active read and one active write per target.
- Address MSB selects the destination: `0` routes to target 0; `1` routes to target 1.

## Functional blocks

### Address routing
The most significant address bit selects one of the two target ports. The current design assumes the address space is divided by that bit; it does not implement an unmapped-address DECERR path.

### Arbitration
AW and AR requests are arbitrated independently per target. A round-robin preference bit changes after an accepted address request. Requests from a master that already has an outstanding transaction in that direction are not eligible.

### Write channel
AW and W handshakes are independent. After a target accepts AW, the interconnect stores the originating master and routes W data/strobes from that owner. The B response is routed back to the same master after the W channel has completed. The current subset allows only one active write per target.

### Read channel
After a target accepts AR, the interconnect stores the originating master. R data and response are routed back to that master until the response handshake completes. The current subset allows one active read per target.

## Key verification invariants

- Only one selected master drives each target address channel at a time.
- An accepted write address establishes ownership for subsequent write data and response routing.
- An accepted read address establishes ownership for the corresponding read response.
- Master request payloads must remain stable while VALID is asserted and READY is low.
- Byte strobes update only the selected byte lanes in the target model.
- Simultaneous requests to different targets can make progress independently.
- Contending requests to the same target must not be lost.

## Deliberate limitations

This is not a full AXI4 interconnect. It does not support bursts, IDs, multiple outstanding transactions per master, address remapping, or a DECERR path for unmapped addresses. These limitations are explicit so verification claims match the implemented design.
