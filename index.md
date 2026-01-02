---
layout: default
---

[![CS6868 Banner]({{ site.baseurl }}/assets/images/chennai_artdeco1.jpg)](https://www.madrasinherited.in/)
<p style="text-align: center; font-size: 0.85em; color: #666; margin-top: -1rem; margin-bottom: 2rem;">
Photo © <a href="https://www.madrasinherited.in/" target="_blank">Madras Inherited</a>
</p>

# CS6868: Concurrent Programming

## Course Overview

This course explores the fundamentals of concurrent and parallel programming with a focus on shared-memory multiprocessor systems. You'll learn to design and implement correct, efficient concurrent programs while understanding the theoretical foundations and practical challenges of concurrency and parallelism.

**Key Topics:**

- Mutual exclusion and synchronization primitives
- Concurrent data structures and algorithms
- Lock-free and wait-free programming
- Memory models and consistency
- Spinlocks and contention management
- Effect handlers and algebraic effects
- Practical multicore programming with OCaml 5

The course uses **OCaml 5** with native support for parallelism via [domains](https://ocaml.org/manual/5.4/api/Domain.html) and concurrency via [effect handlers](https://ocaml.org/manual/5.4/api/Effect.html), providing hands-on experience with modern concurrent programming techniques.

## Prerequisites

- OCaml parts of CS3100 or equivalent functional programming experience
- Basic understanding of operating systems and computer architecture

## Essential Details

- **Instructor:** [KC Sivaramakrishnan](http://kcsrk.info), who goes by "KC".
- **Where:**
- **When:**
- **Slack**:
- **Moodle**:
- **TAs:**

| Name | Email (@smail.iitm.ac.in) |
|------|---------------------------|
|      |                           |

Liaise with the TAs over email about where to meet.

## Grading

| Item                              | Weightage (%) |
|-----------------------------------|---------------|
| In-class short quizzes (best 5/6) | 20            |
| Mid-term exam                     | 20            |
| End semester exam                 | 20            |
| Programming assignments (4)       | 24            |
| Research mini project             | 16            |

We will use absolute grading: S 90, A 80, B 70, C 60, D 50, E 35.

## Acknowledgements

This course material is inspired by and adapted from:

- [The Art of Multiprocessor Programming, 2nd Edition](https://shop.elsevier.com/books/the-art-of-multiprocessor-programming/herlihy/978-0-12-415950-1) by Maurice Herlihy, Nir Shavit, Victor Luchangco, and Michael Spear
- [YSC4231: Parallel, Concurrent and Distributed Programming](https://ilyasergey.net/YSC4231/) by Ilya Sergey (Yale-NUS College)
- [Control structures in programming languages: from goto to algebraic effects](https://xavierleroy.org/control-structures/) by Xavier Leroy
