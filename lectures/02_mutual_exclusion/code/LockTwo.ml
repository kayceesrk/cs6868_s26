(* LockTwo.ml
 *
 * OCaml implementation of LockTwo mutual exclusion algorithm
 * Ported from LockTwo.java (Herlihy & Shavit examples)
 *
 * Second attempt at a mutual exclusion lock for two threads.
 * Not deadlock-free.
 *)

module type LOCK = sig
  val lock : unit -> unit
  (** Acquire the lock, blocking until available *)

  val unlock : unit -> unit
  (** Release the lock *)
end

module LockTwo : LOCK = struct
  (* single shared 'victim' variable *)
  let victim = ref 0

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    victim := i;
    (* let the other go first *)
    while !victim = i do
      () (* spin *)
    done

  let unlock () = ()
end

(* Test program with two threads *)
let counter = ref 0
let iterations = 10

let thread_work () =
  let thread_id = (Domain.self () :> int) - 1 in
  for i = 1 to iterations do
    Printf.printf "Thread %d: attempting lock (iteration %d)\n%!" thread_id i;
    LockTwo.lock ();
    Printf.printf "Thread %d: ENTERED critical section\n%!" thread_id;
    incr counter;
    Printf.printf "Thread %d: LEAVING critical section\n%!" thread_id;
    LockTwo.unlock ()
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "LockTwo Test: Two threads incrementing a counter\n%!";
  Printf.printf "Each thread will increment %d times\n%!" iterations;

  let d1 = Domain.spawn (fun () -> thread_work ()) in
  let d2 = Domain.spawn (fun () -> thread_work ()) in

  Domain.join d1;
  Domain.join d2;

  let final_count = !counter in
  Printf.printf "Expected count: %d\n%!" (2 * iterations);
  Printf.printf "Actual count:   %d\n%!" final_count;

  if final_count = 2 * iterations then
    Printf.printf "✓ Success: Mutual exclusion works!\n%!"
  else Printf.printf "✗ Failed: Race condition detected!\n%!"
