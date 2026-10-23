# Architecture and Design Scope

## Purpose

The DUT connects two independent AXI masters to two memory-mapped targets. This small 2x2 topology is intended to exercise concurrency and cross-interface behavior in a reusable verification environment.

## Conceptual topology

```text
 Master 0 ----+                       +---- Target 0
              |   +---------------+   |
              +-->|               |---+
                  | AXI            |
                  | Interconnect   |
              +-->|               |---+
 Master 1 ----+   +---------------+   +---- Target 1
```

## Planned blocks

- **Address decoder:** Maps legal addresses to exactly one target; defines behavior for unmapped addresses. Configured regions must not overlap.
- **Arbitration:** Chooses among competing eligible masters according to a documented policy. Round-robin is a reasonable initial policy, subject to the final specification.
- **Request routing:** Routes address and write-data channels while preserving channel handshake behavior. Address and data channels must not be assumed to handshake in the same cycle.
- **Response routing:** Returns read and write responses to the requesting master. If IDs and multiple outstanding requests are supported, sufficient routing state must be retained.
- **Target models:** Two independently controlled targets that can introduce wait states and return selected response codes.

## Specification decisions before RTL completion

1. Exact AXI profile/version and supported subset.
2. Address width, data width, ID width, and address map.
3. Supported burst types, transfer sizes, and burst boundary rules.
4. Whether IDs and multiple outstanding transactions are supported.
5. Whether read and write arbitration operate independently.
6. Arbitration policy and fairness assumptions.
7. Reset polarity/synchrony and handling of outstanding transactions.
8. Unmapped-address and target-error behavior.
9. Maximum outstanding request count and any deliberate restrictions.

## Intended invariants

- Each accepted request is routed only to the target selected by the address map.
- Responses return to the correct source master.
- Accepted transactions are neither lost nor duplicated.
- Response matching obeys the supported ordering and ID rules.
- VALID/payload/READY behavior obeys the selected AXI requirements.
- Arbitration chooses only eligible requesters and satisfies the documented policy.
- Reset behavior matches the explicit reset contract and does not misroute stale responses.

These are design intents. Final properties must be written against the actual signal-level interface and frozen specification.