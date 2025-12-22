# Prime Number Programs - OCaml 5 Domains

This directory contains three implementations of prime number printers demonstrating different parallelization strategies using OCaml 5 domains.

## Programs

### 1. Sequential Version (`prime_sequential.ml`)
A baseline sequential implementation that prints all prime numbers up to a given limit.

**Usage:**
```bash
dune exec ./prime_sequential.exe <limit>
```

**Example:**
```bash
dune exec ./prime_sequential.exe 10000
```

### 2. Static Range-Based Parallel (`prime_ranges.ml`)
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

### 3. Dynamic Counter-Based Parallel (`prime_counter.ml`)
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

## Optional Printing Flag

All programs support an optional printing flag to control output. By default, primes are not printed (for faster benchmarking). Use `--print` or `-p` to enable output.

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
