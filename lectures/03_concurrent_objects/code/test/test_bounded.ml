(** Simple test program for the bounded queue *)

module BQ = Concurrent_queues.Bounded_queue

let test_sequential () =
  Printf.printf "=== Sequential Test ===\n%!";
  let q = BQ.create 5 in

  (* Enqueue some elements *)
  Printf.printf "Enqueuing 1, 2, 3...\n%!";
  BQ.enq q 1;
  BQ.enq q 2;
  BQ.enq q 3;

  (* Dequeue and print *)
  Printf.printf "Dequeued: %d\n%!" (BQ.deq q);
  Printf.printf "Dequeued: %d\n%!" (BQ.deq q);

  (* Enqueue more *)
  Printf.printf "Enqueuing 4, 5...\n%!";
  BQ.enq q 4;
  BQ.enq q 5;

  (* Dequeue remaining *)
  Printf.printf "Dequeued: %d\n%!" (BQ.deq q);
  Printf.printf "Dequeued: %d\n%!" (BQ.deq q);
  Printf.printf "Dequeued: %d\n%!" (BQ.deq q);

  (* Test exceptions *)
  Printf.printf "\nTesting exceptions...\n%!";
  begin try
    ignore (BQ.deq q);
    Printf.printf "ERROR: should have raised Empty\n%!"
  with BQ.Empty ->
    Printf.printf "Correctly raised Empty on empty queue\n%!"
  end;

  (* Fill the queue *)
  for i = 1 to 5 do
    BQ.enq q i
  done;

  begin try
    BQ.enq q 99;
    Printf.printf "ERROR: should have raised Full\n%!"
  with BQ.Full ->
    Printf.printf "Correctly raised Full on full queue\n%!"
  end;

  Printf.printf "\n"

let test_concurrent () =
  Printf.printf "=== Concurrent Test ===\n%!";
  let q = BQ.create 100 in
  let num_threads = 4 in
  let items_per_thread = 25 in

  (* Producer threads *)
  let producers = List.init num_threads (fun id ->
    Domain.spawn (fun () ->
      for i = 1 to items_per_thread do
        let value = id * 1000 + i in
        BQ.enq q value;
        (* Printf.printf "Thread %d enqueued %d\n%!" id value *)
      done;
      Printf.printf "Producer %d finished\n%!" id
    )
  ) in

  (* Consumer threads *)
  let results = Array.make num_threads [] in
  let consumers = List.init num_threads (fun id ->
    Domain.spawn (fun () ->
      let items = ref [] in
      for _ = 1 to items_per_thread do
        let value = BQ.deq q in
        items := value :: !items;
        (* Printf.printf "Thread %d dequeued %d\n%!" id value *)
      done;
      results.(id) <- List.rev !items;
      Printf.printf "Consumer %d finished\n%!" id
    )
  ) in

  (* Wait for all threads *)
  List.iter Domain.join producers;
  List.iter Domain.join consumers;

  (* Verify all items *)
  let all_items = Array.fold_left (@) [] results in
  let all_items_sorted = List.sort compare all_items in
  let expected = List.init (num_threads * items_per_thread) (fun i ->
    let thread_id = i / items_per_thread in
    let item_id = (i mod items_per_thread) + 1 in
    thread_id * 1000 + item_id
  ) |> List.sort compare in

  if all_items_sorted = expected then
    Printf.printf "✓ All %d items accounted for correctly\n%!" (List.length all_items)
  else
    Printf.printf "✗ ERROR: Item mismatch!\n%!";

  Printf.printf "\n"

let () =
  test_sequential ();
  test_concurrent ();
  Printf.printf "All tests completed!\n%!"
