# Parallel Programming Examples - OCaml 5 Domains

This directory contains implementations demonstrating different parallelization strategies using OCaml 5 domains.

## Programs

### Fibonacci Examples

Simple examples demonstrating basic parallel computation with OCaml 5 domains:

Simple examples demonstrating basic parallel computation with OCaml 5 domains:

#### 1. Sequential Fibonacci (`fib.ml`)
A basic sequential Fibonacci implementation using naive recursion.

**Usage:**
```bash
dune exec -- ./fib.exe <n>
```

**Example:**
```bash
dune exec -- ./fib.exe 42
```

#### 2. Parallel Fibonacci (`fib_twice.ml`)
Spawns two domains to compute the same Fibonacci number in parallel, demonstrating basic domain usage.

**Usage:**
```bash
dune exec -- ./fib_twice.exe <n>
```

**Example:**
```bash
dune exec -- ./fib_twice.exe 42
```

**Benchmarking Fibonacci:**
```bash
# Compare sequential vs parallel (note: naive parallel fib may not be faster!)
hyperfine --warmup 3 \
  'dune exec -- ./fib.exe 42' \
  'dune exec -- ./fib_twice.exe 42'

# With custom names
hyperfine --warmup 3 \
  --command-name 'sequential' 'dune exec -- ./fib.exe 42' \
  --command-name 'parallel-2d' 'dune exec -- ./fib_twice.exe 42'
```

**Note**: The parallel version spawns 2 domains computing the same value independently. This is intentionally inefficient to demonstrate domain spawning overhead and the importance of proper parallelization strategies.

### Producer-Consumer Example

#### Producer-Consumer with Can Protocol (`prod_cons.ml`)
Demonstrates the classic producer-consumer synchronization pattern using a "can protocol" for coordination. Bob (producer) stocks a pond with random fish, and Alice (consumer) releases pets to eat the fish. They coordinate using a shared "can" state (up/down) to ensure proper synchronization.

**Features:**
- Can protocol synchronization (similar to the original Alice and Bob example)
- Random fish selection (Salmon, Trout, Bass, Catfish, Tuna)
- Busy-waiting loops for coordination
- Clear trace output showing producer-consumer interaction

**Usage:**
```bash
dune exec -- ./prod_cons.exe
```

**Note**: The program runs indefinitely. Use Ctrl+C to stop, or run with timeout:
```bash
timeout 5 dune exec -- ./prod_cons.exe
```

**Example output:**
```
Starting Producer-Consumer with Can Protocol...
Bob produces fish, Alice's pets consume them.

Bob: Stocking pond with Salmon
Alice: Releasing pets to eat Salmon
Alice: Recapturing pets
Bob: Stocking pond with Trout
Alice: Releasing pets to eat Trout
Alice: Recapturing pets
...
```

### Prime Number Printers

Three implementations of prime number printers with different parallelization approaches:

#### 1. Sequential Version (`prime_sequential.ml`)
A baseline sequential implementation that prints all prime numbers up to a given limit.

**Usage:**
```bash
dune exec ./prime_sequential.exe <limit>
```

**Example:**
```bash
dune exec ./prime_sequential.exe 10000
```

#### 2. Static Range-Based Parallel (`prime_ranges.ml`)
A parallel implementation where the work is statically divided into ranges. Each domain processes a predetermined, non-overlapping range of numbers.

**Characteristics:**
- Static work distribution
- No synchronization needed during computation
- Load may be imbalanced if primes are unevenly distributed

**Usage:**
```bash
dune exec ./prime_ranges.exe <limit> <num_domains>
```

**Example:**
```bash
dune exec ./prime_ranges.exe 10000 4
```

#### 3. Dynamic Counter-Based Parallel (`prime_counter.ml`)
A parallel implementation where domains dynamically fetch work from a shared, thread-safe counter. Each domain gets the next number to check from the counter and continues until all numbers are processed.

**Characteristics:**
- Dynamic work distribution
- Better load balancing
- Uses atomic operations (lock-free)
- Small synchronization overhead per fetch

**Usage:**
```bash
dune exec ./prime_counter.exe <limit> <num_domains>
```

**Example:**
```bash
dune exec ./prime_counter.exe 10000 4
```

## Optional Printing Flag (Prime Programs Only)

Prime number programs support an optional printing flag to control output. By default, primes are not printed (for faster benchmarking). Use `--print` or `-p` to enable output.

**Without printing (default):**
```bash
dune exec -- ./prime_sequential.exe 100
```

**With printing:**
```bash
dune exec -- ./prime_sequential.exe 100 --print
# or
dune exec -- ./prime_sequential.exe 100 -p
```

This is especially useful for benchmarking large datasets where I/O overhead would dominate:
```bash
# Fast: only computation time
dune exec -- ./prime_ranges.exe 10000000 4

# Slow: includes I/O overhead
dune exec -- ./prime_ranges.exe 10000000 4 -p
```

## Building

Build all programs:
```bash
dune build
# or
make build
```

Clean build artifacts:
```bash
dune clean
# or
make clean
```

## Requirements

- OCaml 5.0 or later (for Domain support)
- Dune build system
- [hyperfine](https://github.com/sharkdp/hyperfine) (optional, for benchmarking)

Install hyperfine:
```bash
brew install hyperfine  # macOS
# or cargo install hyperfine
```

## Benchmarking with Hyperfine

The included Makefile provides convenient targets for statistical benchmarking using hyperfine:

**Quick benchmark (1M numbers):**
```bash
make bench-quick
```

**Full benchmark (10M numbers, default):**
```bash
make bench
```

**Compare range vs counter at 4 domains:**
```bash
make bench-compare
```

**Individual benchmarks:**
```bash
make bench-seq      # Sequential only
make bench-range    # Range-based with 2, 4, 8 domains
make bench-counter  # Counter-based with 2, 4, 8 domains
```

**Full benchmark suite:**
```bash
make bench-full  # Exports results.json and results.md
```

All benchmark targets export results to markdown tables for easy comparison.

## Manual Performance Comparison

Try running all three with the same inputs to compare:

```bash
# Sequential baseline
dune exec -- ./prime_sequential.exe 1000000

# Static parallel (4 domains)
dune exec -- ./prime_ranges.exe 1000000 4

# Dynamic parallel (4 domains)
dune exec -- ./prime_counter.exe 1000000 4
```

## Discussion Points

1. **Sequential vs Parallel**: How much speedup do you get with parallelization?
2. **Static vs Dynamic**: Which parallel approach performs better? Why?
3. **Scalability**: What happens when you increase the number of domains?
4. **Load Balance**: The range-based approach may suffer from imbalanced load because prime density varies across ranges
5. **Synchronization Cost**: The counter-based approach has atomic overhead but achieves better load balance
6. **Workload Size**: With larger workloads (100M+), the counter-based approach outperforms range-based due to load balancing benefits

## Typical Results

With 10M numbers on a multi-core system:
- **Sequential**: ~1.1s (baseline)
- **Range-8 domains**: ~300ms (3.8x speedup) - fastest but high variance
- **Counter-4 domains**: ~360ms (3.1x speedup) - best consistency
- **Counter-8 domains**: ~415ms - atomic contention increases

With 100M numbers, load imbalance becomes more severe:
- **Range-4**: ~10.3s
- **Counter-4**: ~9.0s (15% faster due to better load balancing)

## Notes

- Output order is non-deterministic in parallel versions
- Timing includes all computation and I/O
- For large datasets, disable printing for accurate computation benchmarks
- Atomic operations are lock-free and faster than mutex-based synchronization
- The `--` separator is needed when passing flags to programs: `dune exec -- ./prog -p`
- For very large limits, consider redirecting output: `> /dev/null` to measure computation time only
