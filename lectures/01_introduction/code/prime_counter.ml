(* Dynamic prime printer with thread-safe counter *)

let is_prime n =
  if n <= 1 then false
  else if n = 2 then true
  else if n mod 2 = 0 then false
  else
    let rec check_divisor d =
      if d * d > n then true
      else if n mod d = 0 then false
      else check_divisor (d + 2)
    in
    check_divisor 3

(* Thread-safe counter using atomic operations *)
let create_counter initial_value =
  Atomic.make initial_value

let get_and_increment counter =
  Atomic.fetch_and_add counter 1

let create_counter initial_value =
  (ref initial_value, Mutex.create ())

let get_and_increment (counter_ref, mutex) =
  Mutex.lock mutex;
  let value = !counter_ref in
  counter_ref := value + 1;
  Mutex.unlock mutex;
  value

let print_primes_dynamic counter limit do_print =
  let rec loop () =
    let i = get_and_increment counter in
    if i <= limit then begin
      if is_prime i then (
        if do_print then Printf.printf "%d\n" i
      );
      loop ()
    end
  in
  loop ()

let () =
  let limit = int_of_string Sys.argv.(1) in
  let num_domains = int_of_string Sys.argv.(2) in
  let do_print =
    if Array.length Sys.argv > 3 then Sys.argv.(3) = "--print" || Sys.argv.(3) = "-p"
    else false
  in

  let counter = create_counter 1 in
  let start_time = Unix.gettimeofday () in

  (* Create domains that dynamically fetch work from counter *)
  let domains =
    List.init num_domains (fun _ ->
        Domain.spawn (fun () -> print_primes_dynamic counter limit do_print))
  in

  (* Wait for all domains to complete *)
  List.iter Domain.join domains;

  let end_time = Unix.gettimeofday () in
  Printf.printf "\nElapsed time: %.3f ms\n" ((end_time -. start_time) *. 1000.0)
