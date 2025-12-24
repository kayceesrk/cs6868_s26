(* Bakery.ml
 *
 * OCaml implementation of Lamport's Bakery mutual exclusion algorithm
 * From "The Art of Multiprocessor Programming" by Herlihy and Shavit
 *
 * Bakery lock: Works for N threads using a "take a number" approach
 * like in a bakery. Each thread takes a number and waits for its turn.
 * Satisfies mutual exclusion, deadlock-freedom, and fairness.
 *)

module type N_THREAD_LOCK = sig
  type t

  val create : int -> t
  val lock : t -> int -> unit
  val unlock : t -> int -> unit
end

module Bakery : N_THREAD_LOCK = struct
  type label = { counter : int; id : int }
  type t = { flag : bool array; label : label array; n_threads : int }

  (* Helper: returns true if l1 < l2 in lexicographic order *)
  let label_less_than l1 l2 =
    l1.counter < l2.counter || (l1.counter = l2.counter && l1.id < l2.id)

  (* Helper: find the maximum counter value across all labels *)
  let max_counter labels =
    Array.fold_left (fun acc label -> max acc label.counter) 0 labels

  (* Helper: check if there's a conflict with any other thread *)
  let conflict lock me =
    let rec check i =
      if i >= lock.n_threads then false
      else if
        i <> me && lock.flag.(i)
        && label_less_than lock.label.(i) lock.label.(me)
      then true
      else check (i + 1)
    in
    check 0

  let create n_threads =
    {
      flag = Array.make n_threads false;
      label = Array.init n_threads (fun id -> { counter = 0; id });
      n_threads;
    }

  let lock bakery thread_id =
    bakery.flag.(thread_id) <- true;
    let max = max_counter bakery.label in
    bakery.label.(thread_id) <- { counter = max + 1; id = thread_id };
    (* Wait while there's a conflict *)
    while conflict bakery thread_id do
      ()
    done

  let unlock bakery thread_id = bakery.flag.(thread_id) <- false
end

(* Test program with multiple threads *)
let counter = ref 0
let iterations = 100
let n_threads = 4

let thread_work bakery thread_id =
  for _ = 1 to iterations do
    Bakery.lock bakery thread_id;
    (* Critical section *)
    incr counter;
    Bakery.unlock bakery thread_id
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "Bakery Lock Test: %d threads incrementing a counter\n%!"
    n_threads;
  Printf.printf "Each thread will increment %d times\n%!" iterations;

  let bakery = Bakery.create n_threads in

  (* Spawn n_threads domains *)
  let domains =
    Array.init n_threads (fun i ->
        Domain.spawn (fun () -> thread_work bakery i))
  in

  (* Wait for all domains to complete *)
  Array.iter Domain.join domains;

  let final_count = !counter in
  Printf.printf "Expected count: %d\n%!" (n_threads * iterations);
  Printf.printf "Actual count:   %d\n%!" final_count;

  if final_count = n_threads * iterations then
    Printf.printf "✓ Success: Mutual exclusion works!\n%!"
  else Printf.printf "✗ Failed: Race condition detected!\n%!"
