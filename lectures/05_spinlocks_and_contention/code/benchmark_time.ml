(* benchmark_time.ml
 *
 * Measures time to increment a shared counter a fixed total number of times
 * Work is divided across threads to show parallelization speedup/slowdown
 *)

module type LOCK = sig
  type t
  val create : unit -> t
  val lock : t -> unit
  val unlock : t -> unit
  val name : string
end

let benchmark_counter (module L : LOCK) num_threads total_increments =
  let lock = L.create () in
  let counter = ref 0 in
  let increments_per_thread = total_increments / num_threads in

  let thread_work () =
    for _ = 1 to increments_per_thread do
      L.lock lock;
      counter := !counter + 1;
      L.unlock lock;
    done
  in

  let start_time = Unix.gettimeofday () in
  let domains = List.init num_threads (fun _ -> Domain.spawn thread_work) in
  List.iter Domain.join domains;
  let end_time = Unix.gettimeofday () in

  end_time -. start_time

(* Lock registry *)
let lock_registry = [
  ("tas", (module struct
    include Spinlocks.TASLock.TASLock
    let name = "TAS"
  end : LOCK));
  ("ttas", (module struct
    include Spinlocks.TTASLock.TTASLock
    let name = "TTAS"
  end : LOCK));
  ("backoff", (module struct
    include Spinlocks.BackoffLock.DefaultBackoffLock
    let name = "Backoff"
  end : LOCK));
  ("alock", (module struct
    include Spinlocks.ALock.ALock
    let name = "ALock"
  end : LOCK));
]

let parse_locks lock_str =
  let names = String.split_on_char ',' lock_str in
  List.map (fun name ->
    let name = String.trim (String.lowercase_ascii name) in
    match List.assoc_opt name lock_registry with
    | Some lock -> lock
    | None ->
        Printf.eprintf "Unknown lock: %s\n" name;
        Printf.eprintf "Available locks: tas, ttas, backoff, alock\n";
        exit 1
  ) names

let () =
  let total_increments = ref 1_000_000 in
  let runs = ref 5 in
  let max_threads = ref 8 in
  let locks_str = ref "ttas" in

  let speclist = [
    ("--locks", Arg.Set_string locks_str, "Comma-separated list of locks (default: ttas; options: tas,ttas,backoff,alock)");
    ("--increments", Arg.Set_int total_increments, "Total counter increments (default: 1000000)");
    ("--max-threads", Arg.Set_int max_threads, "Maximum number of threads (default: 8)");
    ("--runs", Arg.Set_int runs, "Number of runs (default: 5)");
  ] in

  Arg.parse speclist (fun _ -> ()) "Benchmark shared counter increments";

  let locks = parse_locks !locks_str in

  Printf.printf "=== Shared Counter Benchmark ===\n\n%!";
  Printf.printf "Configuration: %d total increments × %d runs, up to %d threads\n"
    !total_increments !runs !max_threads;
  Printf.printf "Work is divided evenly across threads\n\n%!";

  (* Get lock names for header *)
  let lock_names = List.map (fun lock_mod ->
    let module L = (val lock_mod : LOCK) in
    L.name
  ) locks in

  (* Get baselines for all locks (1 thread) *)
  let baselines = List.map (fun lock_mod ->
    let times_1 = List.init !runs (fun _ ->
      Gc.full_major ();
      benchmark_counter lock_mod 1 !total_increments
    ) in
    List.fold_left (+.) 0.0 times_1 /. float_of_int !runs
  ) locks in
  let avg_baseline = List.fold_left (+.) 0.0 baselines /. float_of_int (List.length baselines) in

  (* Print header *)
  Printf.printf "%-10s" "Threads";
  List.iter (fun name -> Printf.printf " %-12s" (name ^ "(s)")) lock_names;
  Printf.printf " %-12s %-10s\n%!" "Ideal(s)" "Slowdown";

  (* Print separator *)
  let separator_width = 10 + (List.length lock_names * 13) + 13 + 11 in
  Printf.printf "%s\n%!" (String.make separator_width '-');

  (* Benchmark each thread count *)
  for threads = 1 to !max_threads do
    Printf.printf "%-10d" threads;

    (* Run each lock at this thread count *)
    let times = List.map (fun lock_mod ->
      let times = List.init !runs (fun _ ->
        Gc.full_major ();
        benchmark_counter lock_mod threads !total_increments
      ) in
      List.fold_left (+.) 0.0 times /. float_of_int !runs
    ) locks in

    (* Print times for each lock *)
    List.iter (fun avg_time ->
      Printf.printf " %-12.3f" avg_time;
    ) times;

    (* Print ideal time (stays constant - all work is serialized) and actual average slowdown *)
    let ideal_time = avg_baseline in  (* No parallelizable work, ideal time = baseline *)
    let avg_time = List.fold_left (+.) 0.0 times /. float_of_int (List.length times) in
    let slowdown = avg_time /. avg_baseline in  (* >1 means slower than baseline *)
    Printf.printf " %-12.3f %-10.2fx\n%!" ideal_time slowdown;
  done;

  Printf.printf "\nNote: Ideal time stays constant - all work is serialized under the lock\n%!"
