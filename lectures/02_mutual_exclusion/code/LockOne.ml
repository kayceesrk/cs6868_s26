(* LockOne.ml
 *
 * OCaml implementation of LockOne mutual exclusion algorithm
 * From "The Art of Multiprocessor Programming" by Herlihy and Shavit
 *
 * First attempt at a mutual exclusion lock for two threads.
 * Satisfies mutual exclusion but NOT deadlock-free.
 *)

module type LOCK = sig
  val lock : int -> unit
  val unlock : int -> unit
end

module LockOne : LOCK = struct
  (* Two boolean flags, one per thread *)
  let flag = [| false; false |]

  let lock thread_id =
    let i = thread_id in
    let j = 1 - i in
    (* Other thread: if i=0 then j=1, if i=1 then j=0 *)
    flag.(i) <- true;
    (* Wait while the other thread wants to enter critical section *)
    while flag.(j) do
      ()
    done

  let unlock thread_id = flag.(thread_id) <- false
end

(* Test program with two threads *)
let counter = ref 0
let iterations = 10

let thread_work thread_id =
  for i = 1 to iterations do
    Printf.printf "Thread %d: attempting lock (iteration %d)\n%!" thread_id i;
    LockOne.lock thread_id;
    Printf.printf "Thread %d: ENTERED critical section\n%!" thread_id;
    (* Critical section *)
    incr counter;
    (* Unix.sleepf 0.001; *)
    Printf.printf "Thread %d: LEAVING critical section\n%!" thread_id;
    LockOne.unlock thread_id (* Unix.sleepf 0.001; *)
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "LockOne Test: Two threads incrementing a counter\n%!";
  Printf.printf "Each thread will increment %d times\n%!" iterations;

  let d1 = Domain.spawn (fun () -> thread_work 0) in
  let d2 = Domain.spawn (fun () -> thread_work 1) in

  Domain.join d1;
  Domain.join d2;

  let final_count = !counter in
  Printf.printf "Expected count: %d\n%!" (2 * iterations);
  Printf.printf "Actual count:   %d\n%!" final_count;

  if final_count = 2 * iterations then
    Printf.printf "✓ Success: Mutual exclusion works!\n%!"
  else Printf.printf "✗ Failed: Race condition detected!\n%!"
