(* peterson_race.ml
 *
 * Demonstrates data races in Peterson's lock according to OCaml's memory model.
 *
 * From the OCaml manual (https://ocaml.org/manual/5.4/memorymodel.html):
 * - Refs and arrays are NON-ATOMIC locations
 * - Two actions conflict if they access the same non-atomic location and
 *   at least one is a write
 * - A program has a data race if conflicting actions have NO happens-before edge
 * - Happens-before edges come from: program order, ATOMIC operations, domain
 *   spawn/join, and mutex operations (but NOT from plain refs/arrays)
 *
 * Peterson's lock uses plain refs/arrays without establishing happens-before
 * relationships between the domains' accesses to flag and victim. Therefore,
 * this program HAS data races according to OCaml's memory model.
 *
 * TSAN detects these races when there is sufficient concurrent activity.
 * With enough iterations, both domains execute concurrently and TSAN reports
 * the unsynchronized accesses to the victim variable.
 *)

module Peterson = struct
  let flag = [| false; false |]  (* Non-atomic location! *)
  let victim = ref 0              (* Non-atomic location! *)

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    let j = 1 - i in
    flag.(i) <- true;        (* Write to non-atomic location *)
    victim := i;             (* Write to non-atomic location *)
    (* Reads from non-atomic locations - these all race with other domain's writes! *)
    while flag.(j) && !victim = i do
      ()
    done

  let unlock () =
    let i = (Domain.self () :> int) - 1 in
    flag.(i) <- false        (* Write to non-atomic location *)
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
