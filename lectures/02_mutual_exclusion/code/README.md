# Mutual Exclusion Algorithms

OCaml 5 implementations of classic mutual exclusion algorithms from "The Art of Multiprocessor Programming" by Herlihy and Shavit.

## Programs

- **Counter.ml** - Synchronized counter using stdlib Mutex (baseline)
- **LockOne.ml** - First attempt using flags (satisfies mutual exclusion but can deadlock)
- **LockTwo.ml** - Second attempt using victim variable (can deadlock)
- **Peterson.ml** - Combines LockOne + LockTwo (correct for 2 threads)
- **Bakery.ml** - Lamport's bakery algorithm (correct for N threads)

## Building and Running

```bash
# Build all programs
dune build

# Run individual programs
dune exec ./Counter.exe
dune exec ./LockOne.exe
dune exec ./LockTwo.exe
dune exec ./Peterson.exe
dune exec ./Bakery.exe
```

## Key Features

All implementations use `Domain.self()` to automatically identify threads without explicit thread ID parameters. Each program tests the lock by having multiple threads increment a shared counter.
