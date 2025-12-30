(* profile_alock.ml - Simple benchmark for profiling *)

let () =
  let threads = 8 in
  let iterations = 100000 in

  let lock = Spinlocks.ALock.DefaultALock.create () in
  let counter = ref 0 in

  let thread_work () =
    for _ = 1 to iterations do
      Spinlocks.ALock.DefaultALock.lock lock;
      counter := !counter + 1;
      Spinlocks.ALock.DefaultALock.unlock lock
    done
  in

  Printf.printf "Running ALock with %d threads × %d iterations\n%!" threads iterations;

  let start_time = Unix.gettimeofday () in
  let domains = List.init threads (fun _ -> Domain.spawn thread_work) in
  List.iter Domain.join domains;
  let end_time = Unix.gettimeofday () in

  Printf.printf "Completed in %.3f seconds\n%!" (end_time -. start_time);
  Printf.printf "Expected: %d, Actual: %d\n%!" (threads * iterations) !counter
