(** Test program for the lock-free queue (SWSR only) *)

module LF = Concurrent_queues.Lockfree_queue

let test_sequential () =
  Printf.printf "=== Sequential Test ===\n%!";
  let q = LF.create 5 in

  (* Enqueue some elements *)
  Printf.printf "Enqueuing 1, 2, 3...\n%!";
  LF.enq q 1;
  LF.enq q 2;
  LF.enq q 3;

  Printf.printf "Size: %d\n%!" (LF.size q);

  (* Dequeue and print *)
  Printf.printf "Dequeued: %d\n%!" (LF.deq q);
  Printf.printf "Dequeued: %d\n%!" (LF.deq q);

  (* Enqueue more *)
  Printf.printf "Enqueuing 4, 5...\n%!";
  LF.enq q 4;
  LF.enq q 5;

  (* Dequeue remaining *)
  Printf.printf "Dequeued: %d\n%!" (LF.deq q);
  Printf.printf "Dequeued: %d\n%!" (LF.deq q);
  Printf.printf "Dequeued: %d\n%!" (LF.deq q);

  (* Test exceptions *)
  Printf.printf "\nTesting exceptions...\n%!";
  Printf.printf "Is empty: %b\n%!" (LF.is_empty q);

  begin try
    ignore (LF.deq q);
    Printf.printf "ERROR: should have raised Empty\n%!"
  with LF.Empty ->
    Printf.printf "Correctly raised Empty on empty queue\n%!"
  end;

  (* Fill the queue *)
  for i = 1 to 5 do
    LF.enq q i
  done;

  Printf.printf "Is full: %b\n%!" (LF.is_full q);

  begin try
    LF.enq q 99;
    Printf.printf "ERROR: should have raised Full\n%!"
  with LF.Full ->
    Printf.printf "Correctly raised Full on full queue\n%!"
  end;

  Printf.printf "\n"

let test_single_writer_single_reader () =
  Printf.printf "=== Single Writer, Single Reader Test (CORRECT USAGE) ===\n%!";
  let num_items = 1000 in
  let q = LF.create num_items in

  (* ONE producer thread *)
  let producer = Domain.spawn (fun () ->
    for i = 1 to num_items do
      LF.enq q i
    done;
    Printf.printf "Producer finished\n%!"
  ) in

  (* ONE consumer thread *)
  let items = ref [] in
  let consumer = Domain.spawn (fun () ->
    for _ = 1 to num_items do
      let value = LF.deq q in
      items := value :: !items
    done;
    Printf.printf "Consumer finished\n%!"
  ) in

  (* Wait for both threads *)
  Domain.join producer;
  Domain.join consumer;

  (* Verify all items *)
  let all_items = List.rev !items in
  let expected = List.init num_items (fun i -> i + 1) in

  if all_items = expected then
    Printf.printf "✓ All %d items received in correct order\n%!" num_items
  else
    Printf.printf "✗ ERROR: Item mismatch or ordering issue!\n%!";

  Printf.printf "\n"

let test_multiple_writers_demonstration () =
  Printf.printf "=== Multiple Writers Test (DEMONSTRATES BUG) ===\n%!";
  Printf.printf "WARNING: This is INCORRECT usage - demonstrating race conditions\n%!";

  let num_threads = 8 in
  let items_per_thread = 100 in
  let total_items = num_threads * items_per_thread in

  (* Run multiple times to increase chance of exposing bug *)
  let failures = ref 0 in
  let runs = 3 in

  for run = 1 to runs do
    let q = LF.create 20 in  (* Small buffer = high contention *)
    let results = ref [] in
    let done_producing = ref false in

    (* Consumer thread to drain the queue *)
    let consumer = Domain.spawn (fun () ->
      while not !done_producing || not (LF.is_empty q) do
        try
          let item = LF.deq q in
          results := item :: !results
        with LF.Empty ->
          Domain.cpu_relax ()
      done
    ) in

    (* Multiple producer threads - THIS IS UNSAFE! *)
    let producers = List.init num_threads (fun id ->
      Domain.spawn (fun () ->
        for i = 1 to items_per_thread do
          let value = id * 1000 + i in
          (* Spin until we can enqueue *)
          let rec try_enq () =
            try
              LF.enq q value
            with LF.Full ->
              (* Tiny delay to encourage interleaving *)
              for _ = 1 to 5 do () done;
              try_enq ()
          in
          try_enq ()
        done
      )
    ) in

    (* Wait for producers *)
    List.iter Domain.join producers;
    done_producing := true;

    (* Wait for consumer *)
    Domain.join consumer;

    (* Check results *)
    let count = List.length !results in
    let seen = Hashtbl.create total_items in
    List.iter (fun item ->
      if Hashtbl.mem seen item then
        Printf.printf "Run %d: Found duplicate item %d!\n%!" run item;
      Hashtbl.replace seen item ()
    ) !results;

    let unique_items = Hashtbl.length seen in

    if count < total_items then begin
      Printf.printf "Run %d: Lost %d items (expected %d, got %d)\n%!"
        run (total_items - count) total_items count;
      incr failures
    end else if unique_items < count then begin
      Printf.printf "Run %d: Got %d items but only %d unique (%d duplicates due to corruption!)\n%!"
        run count unique_items (count - unique_items);
      incr failures
    end else if count = total_items && unique_items = total_items then
      Printf.printf "Run %d: Got all %d items, all unique (lucky timing)\n%!" run count
    else begin
      Printf.printf "Run %d: ERROR - count=%d expected=%d unique=%d\n%!"
        run count total_items unique_items;
      incr failures
    end
  done;

  Printf.printf "\n";
  if !failures > 0 then
    Printf.printf "✗ Race conditions detected in %d/%d runs!\n%!" !failures runs
  else
    Printf.printf "⚠ No race conditions detected (may need more aggressive testing)\n%!";

  Printf.printf "\n"

let () =
  test_sequential ();
  test_single_writer_single_reader ();
  test_multiple_writers_demonstration ();
  Printf.printf "All tests completed!\n%!"
