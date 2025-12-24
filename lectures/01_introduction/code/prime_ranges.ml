(* Static parallel prime printer - range-based division *)

let is_prime n =
  if n <= 1 then false
  else if n = 2 then true
  else if n mod 2 = 0 then false
  else
    let rec check_divisor d =
      (* If n has a divisor d > sqrt(n), then it must also have a corresponding
         divisor n/d < sqrt(n). *)
      if d * d > n then true
      else if n mod d = 0 then false
      else check_divisor (d + 2)
    in
    check_divisor 3

let print_primes_in_range start_range end_range do_print =
  for i = start_range to end_range do
    if is_prime i then if do_print then Printf.printf "%d\n" i
  done

let () =
  let limit = int_of_string Sys.argv.(1) in
  let num_domains = int_of_string Sys.argv.(2) in
  let do_print =
    if Array.length Sys.argv > 3 then
      Sys.argv.(3) = "--print" || Sys.argv.(3) = "-p"
    else false
  in

  let start_time = Unix.gettimeofday () in

  (* Create domains, each handling a range *)
  let domains =
    List.init num_domains (fun i ->
        Domain.spawn (fun () ->
            let block_size = limit / num_domains in
            let start_range = (i * block_size) + 1 in
            let end_range =
              if i = num_domains - 1 then limit else (i + 1) * block_size
            in
            print_primes_in_range start_range end_range do_print))
  in

  (* Wait for all domains to complete *)
  List.iter Domain.join domains;

  let end_time = Unix.gettimeofday () in
  Printf.printf "\nElapsed time: %.3f ms\n" ((end_time -. start_time) *. 1000.0)
