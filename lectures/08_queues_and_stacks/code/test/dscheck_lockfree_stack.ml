(** DSCheck tests for Treiber Stack over the imoplementation provided for lockFreestack*)
(* Here we are using pointer based approach for representing stack.
  type 'a node = {
    value : 'a;
    next  : 'a node option;
  }

*)
module Atomic = Dscheck.TracedAtomic
module Stack = Lockfree_stack

(* ------------------------------------------------------------------ *)
(* Test 1 : two concurrent pushes                                     *)
(* Here we spawning two threads and doing concurrent pushes.
Now final stack should have either a,b or b,a as final state, we are checking property that no value
is lost in lockfree stack, means the implementation doesn't have any race condition. *)
(* ------------------------------------------------------------------ *)


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

	(* empty stack => None
nonempty => Some value *)
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
(* Try to run all possible interleaving *)
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
    let s = Stack.create () in
    let popped = Atomic.make None in

    Atomic.spawn (fun () ->Stack.push s 42);

    Atomic.spawn (fun () ->
      Atomic.set popped (Stack.try_pop s));

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        match Atomic.get popped with
        | None ->
            Stack.try_pop s = Some 42
        | Some 42 ->
            Stack.try_pop s = None
        | _ ->
            false)))
;;

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


(* Conservation Property: *)
(* Two values are pushed and two concurrent pops are executed.this checks that the stack never loses or duplicates elements. *)
let conservation () =
Atomic.trace (fun () ->
let s = create () in

let r1 = Atomic.make None in
let r2 = Atomic.make None in

Atomic.spawn (fun () -> push s 1);
Atomic.spawn (fun () -> push s 2);

Atomic.spawn (fun () ->
  Atomic.set r1 (try_pop s));

Atomic.spawn (fun () ->
  Atomic.set r2 (try_pop s));

Atomic.final (fun () ->
  Atomic.check (fun () ->
    let elems = ref [] in

    (match Atomic.get r1 with
     | Some x -> elems := x :: !elems
     | None -> ());

    (match Atomic.get r2 with
     | Some x -> elems := x :: !elems
     | None -> ());

    let remaining = Atomic.get s in

    let all =
      List.sort compare (!elems @ remaining)
    in

    all = [1; 2])))

let () =
  let open Alcotest in
  run "dscheck_lockfree_stack"
    [ "two-pushes", [ test_case "both values in stack"    `Slow two_pushes  ]
    ; "push-pop",   [ test_case "linearizable push+pop"   `Slow push_and_pop]
    ; "two-pops",   [ test_case "each item popped exactly once" `Slow two_pops    ]
    ; "conservation",[ test_case "elements are neither lost nor duplicated" `Slow conservation ]
    ]
