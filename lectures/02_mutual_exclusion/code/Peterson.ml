(* Peterson.ml
 *
 * OCaml implementation of Peterson mutual exclusion algorithm
 * From "The Art of Multiprocessor Programming" by Herlihy and Shavit
 *
 * Peterson lock: Combines LockOne and LockTwo approaches.
 * Satisfies mutual exclusion, deadlock-freedom, and starvation-freedom for two threads.
 *)

module type LOCK = sig
  val lock : unit -> unit
  (** Acquire the lock, blocking until available *)

  val unlock : unit -> unit
  (** Release the lock *)
end

module Peterson : LOCK = struct
  (* Two boolean flags (from LockOne) and one victim variable (from LockTwo) *)
  let flag = [| false; false |]
  let victim = ref 0

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    let j = 1 - i in
    flag.(i) <- true;
    victim := i;
    (* Wait while the other thread wants to enter AND we're the victim *)
    while flag.(j) && !victim = i do
      ()
    done

  let unlock () =
    let i = (Domain.self () :> int) - 1 in
    flag.(i) <- false
end

(* Test program with two threads *)
let counter = ref 0
let iterations = 100

let thread_work () =
  let thread_id = (Domain.self () :> int) - 1 in
  for _ = 1 to iterations do
    Peterson.lock ();
    (* Critical section *)
    incr counter;
    Peterson.unlock ()
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "Peterson Lock Test: Two threads incrementing a counter\n%!";
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
