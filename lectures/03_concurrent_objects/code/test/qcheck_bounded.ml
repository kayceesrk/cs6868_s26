(** QCheck-Lin Linearizability Test for Lock-Based Bounded Queue

    This test demonstrates that the lock-based bounded queue IS safe for
    multiple writers and multiple readers (MWMR).

    == Expected Result ==

    This test should PASS, confirming that the bounded queue with a mutex
    is linearizable. All concurrent executions should be reconcilable with
    some sequential execution.

    The mutex ensures that:
    - Only one thread accesses the queue state at a time
    - All operations appear atomic
    - No race conditions on head/tail updates

    Compare this with the lock-free queue test which fails!
*)

module BQ = Concurrent_queues.Bounded_queue

(** Lin API specification for the bounded queue *)
module BQSig = struct
  type t = int BQ.t

  (** Create a queue with capacity 10 for testing *)
  let init () = BQ.create 10

  (** No cleanup needed *)
  let cleanup _ = ()

  open Lin

  (** Use small integers (0-99) for test values *)
  let int_small = nat_small

  (** API description using Lin's combinator DSL *)
  let api =
    [ val_ "enq" BQ.enq (t @-> int_small @-> returning_or_exc unit);
      val_ "deq" BQ.deq (t @-> returning_or_exc int_small); ]
end

(** Generate the linearizability test from the specification *)
module BQ_domain = Lin_domain.Make(BQSig)

(** Run 1000 test iterations - should all pass! *)
let () =
  QCheck_base_runner.run_tests_main [
    BQ_domain.lin_test ~count:1000 ~name:"Bounded queue (positive test)";
  ]
