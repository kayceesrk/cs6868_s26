(** QCheck-Lin Linearizability Test for Lock-Free Queue - MPMC

    This test demonstrates that the lock-free queue is NOT safe for
    multiple writers or multiple readers (MPMC - Multiple Producer Multiple Consumer).

    == How Lin Works ==

    1. Test Structure:
       - Sequential prefix: A sequence of operations run sequentially
       - Parallel spawn: Two domains execute operations in parallel
       - Result checking: Lin searches for a sequential interleaving

    2. Linearizability Property:
       A concurrent execution is linearizable if there exists some
       sequential execution of the same operations that produces the
       same results. Each operation should appear to take effect
       instantaneously at some point between its invocation and response.

    3. The API Specification:
       We describe the queue operations using Lin's DSL:
       - val_ "name" function (arg_types @-> ... @-> returning result_type)
       - returning_or_exc: The function may return a value or raise an exception
       - t is the queue type, int_small generates small test integers

    4. What Lin Does:
       - Generates random command sequences with small test values
       - Runs them: sequential prefix, then parallel domains
       - Records all results (return values, exceptions)
       - Searches for a valid sequential interleaving
       - If none found -> linearizability violation!

    5. Why This Queue Fails with MPMC:
       Multiple writers racing on tail updates can:
       - Both read the same tail value
       - Both write to the same array slot (lost items, duplicates)
       - Both increment tail (corrupted state)
       Result: Operations that can't be explained sequentially.

    Expected: This test will FAIL with minimal counterexamples showing
    operations that violate sequential consistency.
*)

module LF = Concurrent_queues.Lockfree_queue

(** Lin API specification for the lock-free queue *)
module LFSig = struct
  type t = int LF.t

  (** Create a queue with capacity 10 for testing *)
  let init () = LF.create 10

  (** No cleanup needed *)
  let cleanup _ = ()

  open Lin

  (** Use small integers (0-99) for test values *)
  let int_small = nat_small

  (** API description using Lin's combinator DSL:
      - val_ registers a function to test
      - (t @-> ...) describes argument types
      - returning_or_exc means function returns a value OR raises an exception
  *)
  let api =
    [ val_ "enq" LF.enq (t @-> int_small @-> returning_or_exc unit);
      val_ "deq" LF.deq (t @-> returning_or_exc int_small); ]
end

(** Generate the linearizability test from the specification *)
module LF_domain = Lin_domain.Make(LFSig)

(** Run 1000 test iterations, each with random command sequences *)
let () =
  QCheck_base_runner.run_tests_main [
    LF_domain.lin_test ~count:1000 ~name:"Lock-free queue MPMC (negative test - expected to fail)";
  ]
