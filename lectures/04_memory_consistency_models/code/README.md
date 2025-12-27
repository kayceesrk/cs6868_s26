# Memory Consistency Models - Code Examples

This directory contains examples demonstrating memory model concepts in OCaml 5.

## 1. CSE Test (`cse.ml`)

Demonstrates how Common Subexpression Elimination (CSE) compiler optimization can affect concurrent programs. The program spawns a domain that reads a reference multiple times while another domain modifies it concurrently.

### Source Code

```ocaml
let t1 a b =
  let r1 = !a * 2 in
  let r2 = !b in
  let r3 = !a * 2 in
  (r1, r2, r3)

let t2 b = b := 0
```

When `a` and `b` point to the same location, CSE optimization can eliminate the second `!a * 2` computation, potentially affecting observable behavior.

### Building and Running

```bash
# Build the program
dune build cse.exe

# Run the program
dune exec ./cse.exe
```

### Checking for CSE Optimization

To verify that the compiler performs CSE optimization, inspect the generated assembly:

```bash
# Build with optimizations and generate assembly
dune build

# View the generated assembly
cat _build/default/.cse.eobjs/native/dune__exe__Cse.s
```

**Look for the `t1` function** (search for `t1_274` or similar):

```arm
; Expected CSE behavior (ARM64 example):
L104:  ldr  x2, [x0, #0]         ; Load !a ONCE
L106:  add  x4, x3, x2, lsl #1   ; Compute r1 = !a * 2
L107:  ldr  x5, [x1, #0]         ; Load !b (r2)

L114:  str  x4, [x0, #0]         ; Store r1
L115:  str  x5, [x0, #8]         ; Store r2
L116:  str  x4, [x0, #16]        ; Store r3 (REUSES x4!)
```

**Key observation:** The value `!a` is loaded only once (L104), computed once (L106), and the result in register `x4` is stored for both `r1` and `r3`. The compiler has eliminated the redundant `!a * 2` computation.

### Architecture Notes

The assembly output and register names will vary depending on your architecture:

- **ARM64/AArch64**: Registers x0-x30
- **x86_64**: Registers rax, rbx, etc.
- The specific optimization may differ, but CSE should still be observable

### Possible Outcomes

When running the program, you may observe:

- `r1 = 2, r2 = 1, r3 = 2` - all reads before write
- `r1 = 0, r2 = 0, r3 = 0` - all reads after write
- `r1 = 2, r2 = 0, r3 = 0` - reads interleaved with write

The outcome `r1 = 2, r2 = 0, r3 = 2` would theoretically be possible with CSE optimization (same computed value for r1 and r3 despite the value changing), but may not be observed in practice due to timing.

---

## 2. Peterson's Lock with TSAN (`peterson_race.ml`)

Demonstrates that Peterson's lock has data races according to OCaml's memory model, even though it provides correct mutual exclusion. Uses ThreadSanitizer (TSAN) to detect these races at runtime.

### Key Points

- Refs and arrays are **NON-ATOMIC** locations in OCaml's memory model
- Peterson's lock uses plain refs/arrays without establishing happens-before edges
- According to the [OCaml memory model](https://ocaml.org/manual/5.4/memorymodel.html), this constitutes a data race
- TSAN detects the unsynchronized accesses to the `victim` variable when domains execute concurrently

### Building with TSAN

This example requires an OCaml compiler with ThreadSanitizer support:

```bash
# First, install TSAN-enabled OCaml compiler
opam switch create 5.4.0+tsan ocaml-option-tsan

# Build and run
dune build peterson_race.exe
dune exec ./peterson_race.exe
```

### Expected Output

The program will show TSAN warnings about data races in the `lock` function:

```
Testing Peterson's lock with 10000 iterations per domain...
==================
WARNING: ThreadSanitizer: data race (pid=...)
  Write of size 8 at 0x... by thread T4:
    #0 camlDune__exe__Peterson_race$lock_278
    ...
  Previous read of size 8 at 0x... by thread T1:
    #0 camlDune__exe__Peterson_race$lock_278
    ...
Final counter value: 20000 (expected: 20000)
```

Despite the data races, the counter reaches the correct value, demonstrating that Peterson's lock provides mutual exclusion even though it violates OCaml's data-race-free guarantee.
