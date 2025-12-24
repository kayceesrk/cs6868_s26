(* LockTwo.ml
 *
 * OCaml implementation of LockTwo mutual exclusion algorithm
 * Ported from LockTwo.java (Herlihy & Shavit examples)
 *
 * Second attempt at a mutual exclusion lock for two threads.
 * Not deadlock-free.
 *)

module type LOCK = sig
  val lock : int -> unit
  val unlock : int -> unit
end

module LockTwo : LOCK = struct
  (* single shared 'victim' variable *)
  let victim = ref 0

  let lock thread_id =
    let i = thread_id in
    victim := i;
    (* let the other go first *)
    while !victim = i do
      () (* spin *)
    done

  let unlock _thread_id = ()
end

(* Test program with two threads *)
let counter = ref 0
let iterations = 10

let thread_work thread_id =
  for i = 1 to iterations do
    Printf.printf "Thread %d: attempting lock (iteration %d)\n%!" thread_id i;
    LockTwo.lock thread_id;
    Printf.printf "Thread %d: ENTERED critical section\n%!" thread_id;
    incr counter;
    Printf.printf "Thread %d: LEAVING critical section\n%!" thread_id;
    LockTwo.unlock thread_id
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "LockTwo Test: Two threads incrementing a counter\n%!";
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
