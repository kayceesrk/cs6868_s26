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
