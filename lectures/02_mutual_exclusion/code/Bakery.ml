(* Bakery.ml
 *
 * OCaml implementation of Lamport's Bakery mutual exclusion algorithm
 * From "The Art of Multiprocessor Programming" by Herlihy and Shavit
 *
 * Bakery lock: Works for N threads using a "take a number" approach
 * like in a bakery. Each thread takes a number and waits for its turn.
 * Satisfies mutual exclusion, deadlock-freedom, and fairness.
 *)

module type BAKERY = sig
  type t
  (** Abstract lock type *)

  val create : int -> t
  (** Create a new bakery lock for n threads *)

  val lock : t -> unit
  (** Acquire the lock, blocking until available *)

  val unlock : t -> unit
  (** Release the lock *)
end

(* Helper: exists with indices on two arrays *)
let exists2i f arr1 arr2 =
  let n = Array.length arr1 in
  let rec loop i =
    if i >= n then false else if f i arr1.(i) arr2.(i) then true else loop (i + 1)
  in
  loop 0

module Bakery : BAKERY = struct
  type t = { flag : bool array; label : int array }
  let create n_threads =
    { flag = Array.make n_threads false; label = Array.make n_threads 0 }

  (* Helper: find the maximum counter value across all labels *)
  let max_counter labels = Array.fold_left max 0 labels

  (* Helper: check if there's a conflict with any other thread *)
  let conflict bakery me my_label =
    exists2i
      (fun i flag label ->
        i <> me && flag && (label < my_label || (label = my_label && i < me)))
      bakery.flag bakery.label

  let lock bakery =
    let thread_id = (Domain.self () :> int) - 1 in
    bakery.flag.(thread_id) <- true;
    let max = max_counter bakery.label in
    let my_label = max + 1 in
    bakery.label.(thread_id) <- my_label;
    (* Wait while there's a conflict *)
    while conflict bakery thread_id my_label do
      ()
    done

  let unlock bakery =
    let thread_id = (Domain.self () :> int) - 1 in
    bakery.flag.(thread_id) <- false
end

(* Test program with multiple threads *)
let counter = ref 0
let iterations = 100
let n_threads = 4

let thread_work bakery =
  let thread_id = (Domain.self () :> int) - 1 in
  for _ = 1 to iterations do
    Bakery.lock bakery;
    (* Critical section *)
    incr counter;
    Bakery.unlock bakery
  done;
  Printf.printf "Thread %d completed\n%!" thread_id

let () =
  Printf.printf "Bakery Lock Test: %d threads incrementing a counter\n%!"
    n_threads;
  Printf.printf "Each thread will increment %d times\n%!" iterations;

  let bakery = Bakery.create n_threads in

  (* Spawn n_threads domains *)
  let domains =
    Array.init n_threads (fun _i -> Domain.spawn (fun () -> thread_work bakery))
  in

  (* Wait for all domains to complete *)
  Array.iter Domain.join domains;

  let final_count = !counter in
  Printf.printf "Expected count: %d\n%!" (n_threads * iterations);
  Printf.printf "Actual count:   %d\n%!" final_count;

  if final_count = n_threads * iterations then
    Printf.printf "✓ Success: Mutual exclusion works!\n%!"
  else Printf.printf "✗ Failed: Race condition detected!\n%!"
