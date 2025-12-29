(* peterson_race_fixed.ml
 *)

module Peterson = struct
  let flag = [| Atomic.make false; Atomic.make false |]  (* Non-atomic location! *)
  let victim = Atomic.make  0              (* Non-atomic location! *)

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    let j = 1 - i in
    Atomic.set flag.(i) true;        (* Write to atomic location *)
    Atomic.set victim i;             (* Write to atomic location *)
    (* Reads from atomic locations *)
    while Atomic.get flag.(j) && Atomic.get victim = i do
      ()
    done

  let unlock () =
    let i = (Domain.self () :> int) - 1 in
    Atomic.set flag.(i) false        (* Write to atomic location *)
end

let counter = ref 0

let thread_work () =
  for _ = 1 to 10000 do
    Peterson.lock ();
    incr counter;
    Peterson.unlock ()
  done

let () =
  Printf.printf "Testing Peterson's lock with 10000 iterations per domain...\n%!";

  let d1 = Domain.spawn thread_work in
  let d2 = Domain.spawn thread_work in
  Domain.join d1;
  Domain.join d2;

  Printf.printf "Final counter value: %d (expected: 20000)\n" !counter
