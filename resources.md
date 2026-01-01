---
layout: page
title: Resources
permalink: /resources/
---

# Software

## OCaml 5

This course requires **OCaml 5.4 or later** for native support of parallelism (domains) and concurrency (effect handlers).

### Installation

Follow the official [OCaml installation guide](https://ocaml.org/docs/install.html). We recommend using `opam`, the OCaml package manager.

**Quick Start (Linux/macOS/WSL):**

```bash
bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)"
opam init
opam switch create 5.4.0
opam install ocaml-lsp-server odoc ocamlformat utop dune
```

**Windows Users:** Use WSL (Windows Subsystem for Linux) for best compatibility.

### Development Environment

We recommend **Visual Studio Code** with the [OCaml Platform](https://marketplace.visualstudio.com/items?itemName=ocamllabs.ocaml-platform) extension for:

- Syntax highlighting and formatting
- Type information on hover
- Jump to definition
- Error checking
- Auto-completion

Other editors with good OCaml support: Emacs (with Tuareg/Merlin), Vim (with Merlin/coc.nvim).

## Build Tools

- **Dune**: OCaml build system (installed via opam above)
- **Make**: Some examples use Makefiles for convenience

## Benchmarking Tools

- **Hyperfine**: Command-line benchmarking tool - [Installation](https://github.com/sharkdp/hyperfine)

# Learning Resources

## Concurrent Programming

### Primary Textbooks

- **The Art of Multiprocessor Programming (2nd Edition)** by Maurice Herlihy, Nir Shavit, Victor Luchangco, and Michael Spear.
  [Publisher Link](https://shop.elsevier.com/books/the-art-of-multiprocessor-programming/herlihy/978-0-12-415950-1)

  Comprehensive coverage of concurrent algorithms, memory models, and synchronization primitives.

- **Control structures in programming languages: from goto to algebraic effects** by Xavier Leroy.
  [Free Online](https://xavierleroy.org/control-structures/)

  Essential reading on control structures, continuations, and effect handlers - foundational concepts for understanding concurrency and algebraic effects in OCaml 5.

## OCaml 5 Multicore

### Documentation

- **OCaml 5 Manual**: [Domains](https://ocaml.org/manual/5.4/api/Domain.html) and [Effect Handlers](https://ocaml.org/manual/5.4/api/Effect.html)

- **OCaml Multicore Wiki**: [github.com/ocaml-multicore/ocaml-multicore/wiki](https://github.com/ocaml-multicore/ocaml-multicore/wiki)

### Tutorials

- **Parallel Programming in Multicore OCaml**: [v2.ocaml.org/releases/5.0/manual/parallelism.html](https://v2.ocaml.org/releases/5.0/manual/parallelism.html)

- **Introduction to Effect Handlers**: [OCaml.org Tutorial](https://ocaml.org/docs/effects)

## General OCaml Resources

### For Beginners

- **OCaml Programming: Correct + Efficient + Beautiful** by Michael Clarkson et al. [cs3110.github.io/textbook](https://cs3110.github.io/textbook/cover.html)

  Excellent introduction to functional programming and OCaml.

- **Real World OCaml (2nd Edition)** by Yaron Minsky, Anil Madhavapeddy and Jason Hickey. [dev.realworldocaml.org](https://dev.realworldocaml.org/)

  Practical OCaml programming with real-world examples.

### Reference

- **OCaml Manual**: [ocaml.org/manual](https://ocaml.org/manual/)

- **OCaml API Documentation**: [ocaml.org/api](https://ocaml.org/api/)

### Practice

- **99 OCaml Problems**: [ocaml.org/problems](https://ocaml.org/problems)

- **Exercism OCaml Track**: [exercism.org/tracks/ocaml](https://exercism.org/tracks/ocaml)

## Systems and Architecture

### Background Reading

- **Computer Architecture: A Quantitative Approach** by Hennessy and Patterson

  Essential for understanding memory hierarchies, cache coherence, and multiprocessor systems.

- **Operating Systems: Three Easy Pieces** by Remzi and Andrea Arpaci-Dusseau. Free at [pages.cs.wisc.edu/~remzi/OSTEP/](https://pages.cs.wisc.edu/~remzi/OSTEP/)

  Chapters on concurrency and synchronization.

## Additional Topics

### Memory Models

- **C/C++ Memory Model**: [cppreference.com/w/cpp/atomic/memory_order](https://en.cppreference.com/w/cpp/atomic/memory_order)

- **Linux Kernel Memory Barriers**: [kernel.org documentation](https://www.kernel.org/doc/Documentation/memory-barriers.txt)

### Lock-Free Programming

- **The Art of Multiprocessor Programming** (primary textbook above) has excellent coverage

- **Preshing on Programming**: [preshing.com](https://preshing.com/) - Blog with excellent articles on concurrency and lock-free programming

## Online Communities

- **OCaml Discuss**: [discuss.ocaml.org](https://discuss.ocaml.org/)

- **OCaml Discord**: [discord.gg/cCYQbqN](https://discord.gg/cCYQbqN)

- **r/ocaml**: [reddit.com/r/ocaml](https://reddit.com/r/ocaml)
