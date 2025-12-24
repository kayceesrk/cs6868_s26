(* Sequential prime number printer *)

let is_prime n =
  if n <= 1 then false
  else if n = 2 then true
  else if n mod 2 = 0 then false
  else begin
    let rec check_divisor d =
      if d * d > n then true
      else if n mod d = 0 then false
      else check_divisor (d + 2)
    in
    check_divisor 3
  end

let print_primes limit do_print =
  for i = 1 to limit do
    if is_prime i then if do_print then Printf.printf "%d\n" i
  done

let () =
  let limit = int_of_string Sys.argv.(1) in
  let do_print =
    if Array.length Sys.argv > 2 then
      Sys.argv.(2) = "--print" || Sys.argv.(2) = "-p"
    else false
  in
  let start_time = Unix.gettimeofday () in
  print_primes limit do_print;
  let end_time = Unix.gettimeofday () in
  Printf.printf "\nElapsed time: %.3f ms\n" ((end_time -. start_time) *. 1000.0)
