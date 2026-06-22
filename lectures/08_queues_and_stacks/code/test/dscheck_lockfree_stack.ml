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

let two_pushes () =
  Atomic.trace (fun () ->
    let s = Stack.create () in

    Atomic.spawn (fun () -> Stack.push s 1);
    Atomic.spawn (fun () -> Stack.push s 2);

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        let r1 = Stack.try_pop s in
        let r2 = Stack.try_pop s in
        let r3 = Stack.try_pop s in

        match r1, r2, r3 with
        | Some a, Some b, None -> List.sort compare [ a; b ] = [ 1; 2 ]
        | _ -> false)))
;;

(* ------------------------------------------------------------------ *)
(* Test 2 : push/pop race                                             *)
(* ------------------------------------------------------------------ *)

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
(* Test 3 : two concurrent pops                                       *)
(* ------------------------------------------------------------------ *)

let two_pops () =
  Atomic.trace (fun () ->
    let s = Stack.create () in

    Stack.push s 1;
    Stack.push s 2;

    let r1 = Atomic.make None in
    let r2 = Atomic.make None in

    Atomic.spawn (fun () -> Atomic.set r1 (Stack.try_pop s));

    Atomic.spawn (fun () -> Atomic.set r2 (Stack.try_pop s));

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        match Atomic.get r1, Atomic.get r2 with
        | Some a, Some b ->
            List.sort compare [ a; b ] = [ 1; 2 ]
            && Stack.try_pop s = None
        | _ ->
            false)))
;;

(* ------------------------------------------------------------------ *)
(* Test 4 : conservation property                                     *)
(* ------------------------------------------------------------------ *)

let conservation () =
  Atomic.trace (fun () ->
    let s = Stack.create () in

    let r1 = Atomic.make None in
    let r2 = Atomic.make None in

    Atomic.spawn (fun () -> Stack.push s 1);
    Atomic.spawn (fun () -> Stack.push s 2);
    Atomic.spawn (fun () -> Atomic.set r1 (Stack.try_pop s));
    Atomic.spawn (fun () -> Atomic.set r2 (Stack.try_pop s));

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        let elems = ref [] in

        (match Atomic.get r1 with
         | Some x -> elems := x :: !elems
         | None -> ());

        (match Atomic.get r2 with
         | Some x -> elems := x :: !elems
         | None -> ());

        (match Stack.try_pop s with
         | Some x -> elems := x :: !elems
         | None -> ());

        (match Stack.try_pop s with
         | Some x -> elems := x :: !elems
         | None -> ());

        List.sort compare !elems = [ 1; 2 ])))
;;

(* ------------------------------------------------------------------ *)
(* Test 5 : LIFO property                                             *)
(* ------------------------------------------------------------------ *)

let lifo_property () =
  Atomic.trace (fun () ->
    let s = Stack.create () in

    Stack.push s 1;
    Stack.push s 2;
    Stack.push s 3;

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        Stack.pop s = 3
        && Stack.pop s = 2
        && Stack.pop s = 1)))
;;

(* ------------------------------------------------------------------ *)
(* Test 6 : empty stack                                               *)
(* ------------------------------------------------------------------ *)

let empty_stack () =
  Atomic.trace (fun () ->
    let s = Stack.create () in

    Atomic.final (fun () ->
      Atomic.check (fun () ->
        Stack.try_pop s = None)))
;;

(* ------------------------------------------------------------------ *)
(* Alcotest runner                                                    *)
(* ------------------------------------------------------------------ *)

let () =
  let open Alcotest in
  run "dscheck_treiber_stack"
    [
      ( "two-pushes", [ test_case "both pushed values present" `Slow two_pushes; ] );
      ( "push-pop", [ test_case "linearizable push/pop race" `Slow push_and_pop; ] );
      ( "two-pops", [ test_case "each value popped exactly once" `Slow two_pops; ] );
      ( "conservation", [ test_case "no lost or duplicated elements" `Slow conservation; ] );
      ( "empty", [ test_case "empty stack returns None" `Slow empty_stack; ] );
    ]
