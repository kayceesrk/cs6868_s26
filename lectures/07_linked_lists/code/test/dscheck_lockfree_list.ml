(** DSCheck tests for Lock-Free List *)

module Atomic = Dscheck.TracedAtomic
module L = Lockfree_list

(*
  TEST1:
    Concurrent threads trying to push same ele, but becuase we can't have 
    duplicates only one should succeed
*)
let two_adds_same_element () =
  Atomic.trace (fun () ->
    let l  = L.create () in
    (* We will be using two flags r1, r2 to see which thread succedds in pushing value.  *)
    let r1 = Atomic.make false in
    let r2 = Atomic.make false in

    Atomic.spawn (fun () -> Atomic.set r1 (L.add l 1));
    Atomic.spawn (fun () -> Atomic.set r2 (L.add l 1));

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        let a = Atomic.get r1 in

        (* This says only one of them should be true, 
        bothof them can't be true at same time and lists should contain value 1 *)
        let b = Atomic.get r2 in (a || b) && not (a && b) && L.contains l 1 
      )))

(* TEST 2:
        Two concurrent adds of diff elements.
        Both should succedd and both values should be present insidelist. 
       *)

let two_adds_distinct_elements () =
  Atomic.trace (fun () ->
    let l  = L.create () in
    let r1 = Atomic.make false in
    let r2 = Atomic.make false in

    Atomic.spawn (fun () -> Atomic.set r1 (L.add l 1));
    Atomic.spawn (fun () -> Atomic.set r2 (L.add l 2));

    (* The final goal is to check: Both were successful in pushing values, meaning r1 and r2 should be true 
    and lists should contain both values as well *)
    Atomic.final (fun () ->
      Atomic.check (fun () ->
        Atomic.get r1 && Atomic.get r2  && L.contains l 1  && L.contains l 2
      )))
(* Alcotest runner
        Basically a test suite runner like we have used gtests for c++.
        Prvoide verbose output when any test case fails.
        Have two modes: Slow & Quick, we are using slow, because dscheck can takes seconds for exploring all interleavings.

*)

let () =
  let open Alcotest in
  run "dscheck_lockfree_list"
    [ "no-duplicates", [ test_case "concurrent adds of same element"      `Slow two_adds_same_element      ]
    ; "no-lost-adds",  [ test_case "concurrent adds of distinct elements" `Slow two_adds_distinct_elements ]
