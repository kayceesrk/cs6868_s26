(* Counter.ml
 *
 * Example showing two threads incrementing a shared counter WITH synchronization.
 * Uses OCaml's standard library Mutex to protect the critical section.
 *)

module type COUNTER = sig
  type t
  (** Abstract counter type *)

  val create : unit -> t
  (** Create a new counter initialized to 0 *)

  val get_and_increment : t -> int
  (** Atomically get current value and increment, returns old value *)

  val get_count : t -> int
  (** Get current count *)
end

module Counter : COUNTER = struct
  type t = { counter : int ref; mutex : Mutex.t }

  let create () = { counter = ref 0; mutex = Mutex.create () }

  let get_and_increment t =
    Mutex.lock t.mutex;
    let old_value = !(t.counter) in
    t.counter := old_value + 1;
    Mutex.unlock t.mutex;
    old_value

  let get_count t =
    Mutex.lock t.mutex;
    let count = !(t.counter) in
    Mutex.unlock t.mutex;
    count
end

let iterations = 10000

let thread_work counter =
  let thread_id = (Domain.self () :> int) - 1 in
  for _ = 1 to iterations do
    let _ = Counter.get_and_increment counter in
    ()
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf
    "Counter Test (WITH STDLIB MUTEX): Two threads incrementing a counter\n%!";
  Printf.printf "Each thread will increment %d times\n%!" iterations;

  let counter = Counter.create () in

  let d1 = Domain.spawn (fun () -> thread_work counter) in
  let d2 = Domain.spawn (fun () -> thread_work counter) in

  Domain.join d1;
  Domain.join d2;

  let final_count = Counter.get_count counter in
  Printf.printf "\nExpected count: %d\n%!" (2 * iterations);
  Printf.printf "Actual count:   %d\n%!" final_count;

  if final_count = 2 * iterations then
    Printf.printf "✓ Success: Mutex synchronization works!\n%!"
  else
    Printf.printf "✗ Failed: Lost %d increments\n%!"
      ((2 * iterations) - final_count)
