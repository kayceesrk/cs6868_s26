# Spinlocks and Contention

This directory contains OCaml implementations of various spinlock algorithms from the "Art of Multiprocessor Programming" Chapter 7.

## Code Structure

### Core Lock Implementations

- **Lock.ml** - Common `LOCK` signature that all implementations follow
- **TASLock.ml** - Test-And-Set lock (simple atomic exchange)
- **TTASLock.ml** - Test-Test-And-Set lock (read before write)
- **BackoffLock.ml** - TTAS with exponential backoff
- **ALock.ml** - Array-based queue lock with padding

### Testing and Benchmarking

- **Benchmark.ml** - Shared benchmarking utilities
- **test_*.ml** - Individual correctness tests for each lock
- **benchmark_throughput.ml** - Throughput comparison (ops/sec)
- **benchmark_time.ml** - Time to increment shared counter (demonstrates lock contention)

### Build System

- **dune** - Dune build rules
- **dune-project** - Dune project configuration
- **Makefile** - Convenience wrapper for common commands

## Spinlock Implementations

### 1. TAS Lock (Test-And-Set)

The simplest spinlock using atomic test-and-set operations.

**Files:**

- `TASLock.ml` - Basic implementation with simple test

**How it works:**

- Uses a single atomic boolean to represent lock state
- `lock()`: Continuously tries to atomically set state to true until successful
- `unlock()`: Sets state back to false

**Performance characteristics:**

- Simple but generates high cache coherence traffic
- Every spinning thread performs atomic operations continuously
- Each failed test-and-set invalidates other threads' caches

**Build and run:**

```bash
dune exec ./test_tas.exe
```

### 2. TTAS Lock (Test-Test-And-Set)

Improved spinlock that reads before writing to reduce cache coherence traffic.

**Files:**

- `TTASLock.ml` - Implementation with detailed comments
- `test_ttas.ml` - Correctness test

**How it works:**

- First spin-reads the lock state (cheap, no cache invalidation)
- Only attempts atomic test-and-set when lock appears free
- If test-and-set fails, go back to reading

**Performance characteristics:**

- Much better than TAS under contention
- Read operations don't invalidate other caches
- Only generates coherence traffic when competing for free lock
- Cache line can be shared (S state) while threads spin-read

**Build and run:**

```bash
dune exec ./test_ttas.exe
```

### 3. Backoff Lock

Improved spinlock with exponential backoff to reduce contention.

**Files:**

- `BackoffLock.ml` - Implementation with exponential backoff using Domain.cpu_relax
- `test_backoff.ml` - Correctness test

**How it works:**

- Like TTAS: spin-read until lock appears free
- Try atomic test-and-set
- **New:** If acquisition fails, back off exponentially
- Uses `Domain.cpu_relax()` for efficient waiting
- Backoff delay doubles each time (up to MAX_DELAY)

**Performance characteristics:**

- Best under high contention
- Reduces cache coherence traffic by spreading out retries
- MIN_DELAY and MAX_DELAY need tuning for specific workloads
- Generally: (1, 256) is a good default for most cases

**Build and run:**

```bash
dune exec ./test_backoff.exe
```

### 4. Array Lock (ALock)

Queue-based lock where each thread spins on a different array element.

**Files:**

- `ALock.ml` - Implementation using array of atomic booleans with make_contended
- `test_alock.ml` - Correctness test

**How it works:**

- Array of flags (atomic booleans), one per potential thread
- Uses `Atomic.make_contended()` to prevent false sharing
- Threads take tickets using atomic fetch-and-add
- Each thread spins on its own flag (different cache line)
- Lock holder signals next thread when releasing

**Design notes:**

- Array capacity should match expected thread count
- Uses Domain.DLS to store each domain's slot
- `make_contended` adds padding between array elements

**Performance characteristics:**

- Eliminates spinning cache coherence traffic
- Each thread waits on different memory location
- Traffic only when passing lock between threads
- Current implementation shows moderate performance; may benefit from further optimization

**Build and run:**

```bash
dune exec ./test_alock.exe
```

## Building and Running

### Build all code

```bash
dune build
```

### Run individual tests

```bash
dune exec ./test_tas.exe
dune exec ./test_ttas.exe
dune exec ./test_backoff.exe
dune exec ./test_alock.exe
```

### Run comprehensive benchmark

```bash
# Compare all locks with 1-8 threads (throughput in ops/sec)
dune exec ./benchmark_throughput.exe

# Custom configuration
dune exec ./benchmark_throughput.exe -- --iterations 100000 --runs 10

# Shared counter benchmark (execution time with lock contention)
dune exec ./benchmark_time.exe -- --locks ttas,backoff --increments 1000000 --max-threads 8
```

## Benchmark Results

### macOS (Apple M2, 8 cores)

50K iterations/thread × 5 runs:

```text
Threads           TAS         TTAS      Backoff        ALock
----------------------------------------------------------------
1              31661K       33056K       33475K       43224K
2              13317K       25371K       24564K        9168K
3              10002K       19022K       17359K        9314K
4               9265K       13969K       17449K        8226K
5               3810K        7015K       13393K        4192K
6               2428K        7130K       12600K        2658K
7               2193K        6813K       10811K        2055K
8               2120K        4842K        8440K        1218K
```

**Key findings:**

- **Backoff lock wins** at high thread counts (8.4M ops/sec at 8 threads)
- **TTAS** outperforms simple TAS by 2-3x under contention
- **ALock** has good single-thread performance but suffers from serialization bottleneck
  - `fetch_and_add` enforces strict FIFO ordering
  - Prevents opportunistic lock acquisition when lock becomes free
  - Creates convoy effect: threads must wait for their specific turn

### Linux (Intel Xeon Gold 5120 @ 2.20GHz, 28 cores)

50K iterations/thread × 5 runs:

```text
Threads           TAS         TTAS      Backoff        ALock
----------------------------------------------------------------
1              14179K       13923K        8297K        4984K
2               2763K        3577K        4090K        1385K
3               1950K        2399K        3006K        1463K
4               1684K        1741K        2111K        1490K
5               1437K        1704K        2400K        1557K
6               1469K        1439K        1702K        1564K
7               1143K        1477K        1542K        1742K
8               1010K        1275K        1624K        1808K
```

**Key findings:**

- **ALock performs best** at 8 threads (1.8M ops/sec), unlike macOS where it's worst
- All locks show **significantly lower throughput** compared to macOS (2-6x slower)
- **Backoff** still competitive at moderate thread counts (2.4M at 5 threads)
- Platform differences highlight importance of hardware-specific tuning

## Implementation Details

### TAS vs TTAS

TAS continuously performs atomic operations (high cache coherence traffic), while TTAS reads first (cache line can be shared in S state), only attempting atomic exchange when lock appears free.

### Backoff Strategy

Uses exponential backoff (1 to 256 iterations) with `Domain.cpu_relax()` to reduce cache coherence traffic by spreading out retry attempts.

### ALock Padding

Uses `Atomic.make_contended()` to ensure each array element is on a separate cache line, preventing false sharing between threads spinning on different flags.

### Performance Considerations

- **Cache coherence protocol**: Writes (TAS) vs reads (TTAS) generate different traffic patterns
- **Serialization bottleneck**: ALock's `fetch_and_add` creates strict ordering, hurting scalability
- **Platform differences**: Performance varies significantly between architectures (macOS M-series vs Linux x86)

## References

- "The Art of Multiprocessor Programming" by Maurice Herlihy and Nir Shavit
- Chapter 7: Spin Locks and Contention
