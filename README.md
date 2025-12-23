# CS6868: Concurrent Programming (IITM Spring 2026)

This is the GitHub repo for the course CS6868 Concurrent Programming taught at
IITM in the Spring semester 2026. The course website is here:
https://kcsrk.info/cs6868_s26/.

## Course Overview

This course teaches the fundamentals of concurrent and parallel programming,
with a focus on shared-memory multiprocessor systems. Topics include:

- Principles of concurrent programming
- Mutual exclusion and synchronization
- Concurrent data structures
- Lock-free and wait-free algorithms
- Memory models and consistency
- Parallel programming patterns
- "Concurrency" foundations: continuations, monads, effect handlers
- Practical implementations using OCaml 5's multicore features
- Safe parallel programming with OxCaml

The course uses OCaml 5 with itts native support for parallelism via
[domains](https://ocaml.org/manual/5.4/api/Domain.html) and concurrency via
[effect handlers](https://ocaml.org/manual/5.4/api/Effect.html).

## Repository Structure

- `lectures/` - Lecture materials and code examples
- `assignments.md` - Course assignments
- `schedule.md` - Course schedule
- `resources.md` - Additional learning resources

## Prerequisites

OCaml parts of CS3100 or equivalent experience with functional programming
and basic understanding of operating systems and computer architecture.

## Getting Started

```bash
git clone https://github.com/kayceesrk/cs6868_s26
cd cs6868_s26
```

Refer to individual lecture directories for specific setup instructions.