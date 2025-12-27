# Concurrent Objects - Bounded Queues

OCaml 5 implementations of concurrent queue data structures from "The Art of Multiprocessor Programming" by Herlihy and Shavit.

## Data Structures

### Library (`lib/`)

- **bounded_queue.ml** - Simple lock-based bounded queue (safe for MWMR)
  - Uses a single `Mutex` to protect all operations
  - Safe for Multiple Writers, Multiple Readers
  - Array-based with head/tail indices

- **lockfree_queue.ml** - Lock-free bounded queue (safe ONLY for SRSW)
  - Based on TwoThreadLockFreeQueue from AoMPP Chapter 10
  - No locks, uses mutable fields
  - Only safe for Single Writer, Single Reader
  - NOT safe for multiple writers or multiple readers!

## Tests

### Manual Tests (`test/`)

- **test_bounded.ml** - Manual concurrent test of bounded queue
  - Sequential test (basic operations, exceptions)
  - Concurrent test (4 producers, 4 consumers)
  - Should always pass ✓

- **test_lockfree.ml** - Manual concurrent test of lock-free queue
  - Sequential test (basic operations)
  - SWSR test (1 producer, 1 consumer) - passes ✓
  - MWMR test (8 producers with consumer) - fails ✗
  - Demonstrates race conditions with multiple writers

### QCheck-Lin Tests (`test/`)

- **qcheck_bounded.ml** - Linearizability test of bounded queue
  - Uses QCheck-Lin to systematically test linearizability
  - Runs 1000 random concurrent scenarios
  - Should pass: all executions are linearizable ✓

- **qcheck_lockfree.ml** - Linearizability test of lock-free queue
  - Uses QCheck-Lin to find linearizability violations
  - Should fail: finds minimal counterexamples ✗
  - Demonstrates why the queue is unsafe for MWMR

## Building and Running

```bash
# Build everything
dune build

# Run manual tests
dune exec test/test_bounded.exe
dune exec test/test_lockfree.exe

# Run QCheck-Lin linearizability tests
dune exec test/qcheck_bounded.exe    # Should pass
dune exec test/qcheck_lockfree.exe   # Should fail with counterexample
```

## Dependencies

Install QCheck-Lin for linearizability testing:

```bash
opam install qcheck-lin
```

## Key Concepts

### Linearizability

A concurrent execution is linearizable if there exists some sequential execution of the same operations that produces the same results. Each operation should appear to take effect instantaneously at some point between its invocation and response.

### Why Lock-Free Queue Fails for MWMR

Multiple writers racing on `tail` updates can:

- Both read the same tail value
- Both write to the same array slot (lost items, duplicates)
- Both increment tail (corrupted state)

Multiple readers racing on `head` updates can:

- Both read the same head value
- Both read the same array slot (duplicate items)
- Both increment head (lost items)

### QCheck-Lin Advantages

- **Systematic testing**: Generates hundreds of concurrent scenarios
- **Minimal counterexamples**: Shrinks failures to simplest case
- **Formal verification**: Tests linearizability property
- **Automatic**: No need to manually design test cases

## References

- Nikolaus Huber, Naomi Spargo, Nicolas Osborne, Samuel Hym, and Jan Midtgaard, "Dynamic Verification of OCaml Software with Gospel and Ortac/QCheck-STM", In *Proceedings of TACAS 2025* (Tools and Algorithms for the Construction and Analysis of Systems), <https://janmidtgaard.dk/papers/Huber-al%3ATACAS25.pdf>
