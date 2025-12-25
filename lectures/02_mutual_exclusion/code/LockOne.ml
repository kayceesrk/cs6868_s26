(* LockOne.ml
 *
 * OCaml implementation of LockOne mutual exclusion algorithm
 * From "The Art of Multiprocessor Programming" by Herlihy and Shavit
 *
 * First attempt at a mutual exclusion lock for two threads.
 * Satisfies mutual exclusion but NOT deadlock-free.
 *)

module type LOCK = sig
  val lock : unit -> unit
  (** Acquire the lock, blocking until available *)

  val unlock : unit -> unit
  (** Release the lock *)
end

module LockOne : LOCK = struct
  (* Two boolean flags, one per thread *)
  let flag = [| false; false |]

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    (* ^^ Returns 0 or 1 if you spawn only two domains *)
    let j = 1 - i in
    (* Other thread: if i=0 then j=1, if i=1 then j=0 *)
    flag.(i) <- true;
    (* Wait while the other thread wants to enter critical section *)
    while flag.(j) do
      ()
    done

  let unlock () =
    let i = (Domain.self () :> int) - 1 in
    flag.(i) <- false
end

(* Test program with two threads *)
let counter = ref 0
let iterations = 10
(* Will only work for small iteration counts. Try increasing the number to
   10000. Why? *)

let thread_work () =
  let thread_id = (Domain.self () :> int) - 1 in
  for i = 1 to iterations do
    Printf.printf "Thread %d: attempting lock (iteration %d)\n%!" thread_id i;
    LockOne.lock ();
    Printf.printf "Thread %d: ENTERED critical section\n%!" thread_id;
    (* Critical section *)
    incr counter;
    (* Unix.sleepf 0.001; *)
    Printf.printf "Thread %d: LEAVING critical section\n%!" thread_id;
    LockOne.unlock () (* Unix.sleepf 0.001; *)
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "LockOne Test: Two threads incrementing a counter\n%!";
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
