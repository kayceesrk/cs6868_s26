(** DSCheck test for a lock-free stack (Treiber stack).

    DSCheck works by replacing the standard Atomic module with its own
    TracedAtomic, which records every atomic operation.  It then
    exhaustively replays every possible interleaving of those operations
    across all spawned domains.  Any assertion that fails in *any*
    interleaving is reported.

    Because DSCheck needs to intercept atomic operations at the module
    level, we cannot use the pre-compiled lockfree_stack library here.
    Instead we inline a simplified Treiber stack (no backoff — backoff
    uses Random/cpu_relax which are outside DSCheck's model) using
    [Dscheck.TracedAtomic].  The logic is identical to lockfree_stack.ml. *)

module Atomic = Dscheck.TracedAtomic

(* ------------------------------------------------------------------ *)
(* Inline Treiber stack using TracedAtomic                            *)
(* ------------------------------------------------------------------ *)

exception Empty

(* The whole stack is one atomic cell holding an immutable list.
   push = CAS old (x::old), pop = CAS (x::rest) rest. *)
type 'a t = 'a list Atomic.t

let create () : 'a t = Atomic.make []

let rec push s x =
  let old = Atomic.get s in
  if not (Atomic.compare_and_set s old (x :: old)) then push s x

let rec pop s =
  let old = Atomic.get s in
  match old with
  | [] -> raise Empty
  | x :: rest ->
    if Atomic.compare_and_set s old rest then x
    else pop s

let try_pop s =
  match pop s with
  | v      -> Some v
  | exception Empty -> None

(* ------------------------------------------------------------------ *)
(* Test 1 : two concurrent pushes                                      *)
(* ------------------------------------------------------------------ *)
(* Two domains each push one distinct value onto an empty stack.
   After both finish, the stack must contain exactly those two values
   (in either order — LIFO order depends on which CAS won). *)

let two_pushes () =
  Atomic.trace (fun () ->
    let s = create () in
    Atomic.spawn (fun () -> push s 1);
    Atomic.spawn (fun () -> push s 2);
    Atomic.final (fun () ->
      Atomic.check (fun () ->
        let contents = Atomic.get s in
        List.length contents = 2
        && List.mem 1 contents
        && List.mem 2 contents)))

(* ------------------------------------------------------------------ *)
(* Test 2 : one push and one pop, racing on an empty stack            *)
(* ------------------------------------------------------------------ *)
(* Two valid linearizations:
     (a) pop first  - returns None,  then push - stack = [42]
     (b) push first - stack = [42],  then pop  - returns Some 42, stack = []
   The check accepts both outcomes and rejects everything else. *)

let push_and_pop () =
  Atomic.trace (fun () ->
    let s      = create () in
    let popped = Atomic.make None in
    Atomic.spawn (fun () -> push s 42);
    Atomic.spawn (fun () -> Atomic.set popped (try_pop s));
    Atomic.final (fun () ->
      Atomic.check (fun () ->
        let contents = Atomic.get s in
        match Atomic.get popped with
        | None   -> contents = [42]          (* pop ran before push *)
        | Some v -> v = 42 && contents = []))) (* pop ran after push *)

(* ------------------------------------------------------------------ *)
(* Test 3 : two concurrent pops on a two-element stack                *)
(* ------------------------------------------------------------------ *)
(* Pre-load [2; 1] (2 on top).  Two domains each call try_pop.
   Because the stack has exactly 2 elements and both pops succeed,
   each domain must get a distinct value and the stack ends empty. *)

let two_pops () =
  Atomic.trace (fun () ->
    let s  = create () in
    push s 1;
    push s 2;           (* stack is now [2; 1] *)
    let r1 = Atomic.make None in
    let r2 = Atomic.make None in
    Atomic.spawn (fun () -> Atomic.set r1 (try_pop s));
    Atomic.spawn (fun () -> Atomic.set r2 (try_pop s));
    Atomic.final (fun () ->
      Atomic.check (fun () ->
        match Atomic.get r1, Atomic.get r2 with
        | Some a, Some b ->
            List.sort compare [a; b] = [1; 2]
            && Atomic.get s = []
        | _ -> false)))  (* one pop returning None would be a bug *)


let () =
  let open Alcotest in
  run "dscheck_lockfree_stack"
    [ "two-pushes", [ test_case "both values in stack"    `Slow two_pushes  ]
    ; "push-pop",   [ test_case "linearizable push+pop"   `Slow push_and_pop]
    ; "two-pops",   [ test_case "each item popped exactly once" `Slow two_pops    ]
    ]
