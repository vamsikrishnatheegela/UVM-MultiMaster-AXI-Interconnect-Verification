# Functional Coverage Plan

Functional coverage will measure scenario completion rather than just stimulus generation. The planned covergroups must be implemented and compiled in the selected simulator before reporting percentages.

## Candidate coverpoints

### Transaction attributes
- Read versus write
- Master 0 versus Master 1
- Target 0 versus Target 1
- Single transfer versus each supported burst type
- Transfer size and burst length within the supported subset

### Arbitration and concurrency
- Contention versus no contention
- Winning requester under contention
- Simultaneous requests from both masters
- Masters accessing different targets concurrently
- Read/write overlap if independently supported

### Backpressure and latency
- Immediate handshake
- Short stall and multi-cycle stall
- Independently delayed target responses
- Immediate versus delayed response acceptance

### Responses and errors
- Each supported response code
- Normal completion versus target error
- Response returned to matching master
- Outstanding transaction count if implemented

### Reset
- Reset while idle
- Reset during address handshake
- Reset during write data
- Reset while waiting for response
- Reset with multiple outstanding requests if supported

## Meaningful cross coverage

- Master x target
- Read/write x target
- Arbitration outcome x contention
- Target x response-delay bin
- Traffic type x backpressure level
- Reset phase x transaction state
- Response code x target

Avoid huge, mostly unreachable crosses that add little diagnostic value.

## Sampling and closure

Sample meaningful events such as completed handshakes or transaction completion—not merely sequence requests. On uncovered bins, determine whether stimulus is missing, the bin is unreachable by specification, or a design/specification issue exists. Add directed tests or refine constraints as needed; document justified exclusions.

Code coverage and functional coverage are complementary. Neither alone proves correctness.