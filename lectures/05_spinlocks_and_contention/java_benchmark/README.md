# Java Spinlock Benchmarks

This directory contains Java implementations of various spinlock algorithms and benchmarking infrastructure to compare their performance.

## Overview

The benchmarks test spinlock implementations under different thread counts (1-8 threads) and measure:
- Execution time
- Throughput (operations per second)
- Correctness (verify all increments completed)

## Lock Implementations

The following spinlock implementations are available in the `spin/` directory:

### Basic Locks
- **TASLock**: Test-and-Set lock
- **TTASLock**: Test-and-Test-and-Set lock
- **BackoffLock**: TTAS with exponential backoff

### Array-Based Locks
- **ALock**: Array-based lock
- **ALockPadded**: Array-based lock with padding to avoid false sharing

### Queue-Based Locks
- **CLHLock**: Craig-Landin-Hagersten queue lock
- **MCSLock**: Mellor-Crummey-Scott queue lock
- **HCLHLock**: Hierarchical CLH lock
- **TOLock**: Timeout lock

### Composite Locks
- **CompositeLock**: Combines multiple lock algorithms
- **CompositeFastPathLock**: Fast path optimization
- **HBOLock**: Hierarchical Backoff lock

## Building and Running

### Quick Start

Build and run with default settings:
```bash
make run
```

### Build Only

Compile all Java files:
```bash
make build
```

### Run with Custom Parameters

Run with a specific number of iterations:
```bash
make run-custom ITERATIONS=100000
```

### Clean Build Artifacts

Remove all compiled `.class` files:
```bash
make clean
```

## Benchmark Output Format

The output format is similar to the OCaml `benchmark_all_locks.ml`:

```
=== Java Spinlock Performance Comparison ===

Configuration: 50000 iterations/thread

Lock                 Time       Throughput      Correct
-----------------------------------------------------------------

1 threads:
TAS                   0.015s      3333333 ops/s  ✓
TTAS                  0.012s      4166667 ops/s  ✓
Backoff               0.013s      3846154 ops/s  ✓
ALock                 0.014s      3571429 ops/s  ✓
ALock (padded)        0.013s      3846154 ops/s  ✓

2 threads:
TAS                   0.089s      1123596 ops/s  ✓
TTAS                  0.034s      2941176 ops/s  ✓
...
```

## Benchmark Details

### Test Workload
- Each thread increments a shared counter
- Each increment requires acquiring and releasing the lock
- Default: 50,000 iterations per thread

### Thread Scaling
- Tests run with 1, 2, 4, and 8 threads
- Allows observation of contention effects
- Shows how locks scale under different loads

### Metrics
- **Time**: Wall-clock time for all threads to complete
- **Throughput**: Total operations per second (threads × iterations / time)
- **Correctness**: Verifies final counter value equals expected (threads × iterations)

## Implementation Notes

### LockBenchmark.java
Main benchmarking class that:
- Implements a simple counter protected by locks
- Measures execution time and calculates throughput
- Verifies correctness of concurrent execution
- Formats output for easy comparison

### Lock Interface
All locks implement Java's standard `java.util.concurrent.locks.Lock` interface:
- `void lock()`: Acquire the lock
- `void unlock()`: Release the lock

### Thread Management
- Uses Java threads (not virtual threads)
- ThreadID utility provides unique thread identifiers
- Some locks (ALock, CLHLock) use ThreadLocal storage

## Performance Considerations

### Expected Results
- **Low Contention (1-2 threads)**: Most locks perform similarly
- **High Contention (4-8 threads)**:
  - TTAS typically outperforms TAS
  - Backoff can reduce contention
  - Queue-based locks (CLH, MCS) may excel
  - ALockPadded should outperform ALock

### False Sharing
The padded variant of ALock adds cache line padding to avoid false sharing, which can significantly impact performance on multi-core systems.

### Benchmarking Best Practices
- Run multiple times for consistent results
- Close other applications to reduce interference
- Be aware that JIT compilation affects early runs
- Consider warming up the JVM before measurement

## Customization

To add a new lock to the benchmark:

1. Implement the `Lock` interface in `spin/YourLock.java`
2. Add a benchmark call in `LockBenchmark.java` main method:
   ```java
   benchmarkLock(new YourLock(), "YourLock", threads, iterations);
   ```
3. Rebuild and run

## Comparison with OCaml Implementation

This Java benchmark is designed to produce output comparable to the OCaml `benchmark_all_locks.ml`:
- Similar thread counts (1-8)
- Similar iteration counts (default 50,000)
- Similar output format showing throughput
- Both verify correctness

Key differences:
- Java uses threads, OCaml uses domains
- Java shows throughput in ops/s, OCaml in K ops/s
- Java measures single run, OCaml averages multiple runs

## Requirements

- Java 8 or higher
- Make (for using Makefile)
- Multi-core processor for meaningful results

## Troubleshooting

### Compilation Errors
- Ensure all `.java` files in `spin/` directory are present
- Check Java version: `java -version`

### Runtime Errors
- If you see "ClassNotFoundException", run `make build` first
- For "OutOfMemoryError", reduce iteration count

### Unexpected Results
- JIT compilation can affect first runs - consider multiple runs
- System load affects results - close other applications
- Some locks require proper thread count (e.g., ALock)
