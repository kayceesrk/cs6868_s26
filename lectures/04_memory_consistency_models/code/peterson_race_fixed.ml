(* peterson_race_fixed.ml
 *
 * Demonstrates Peterson's lock using ATOMIC operations, eliminating data races
 * according to OCaml's memory model.
 *
 * Key differences from peterson_race.ml:
 * - Uses Atomic.make, Atomic.get, Atomic.set instead of refs/arrays
 * - Atomic operations establish proper happens-before edges
 * - No data races according to OCaml's memory model
 * - Clean TSAN output (no warnings)
 *
 * From the OCaml manual (https://ocaml.org/manual/5.4/memorymodel.html):
 * - Atomic module provides atomic memory locations
 * - Atomic operations are synchronized and establish happens-before edges
 * - Programs using only atomic operations for shared data are data-race-free
 *)

module Peterson = struct
  let flag = [| Atomic.make false; Atomic.make false |]
  let victim = Atomic.make 0

  let lock () =
    let i = (Domain.self () :> int) - 1 in
    let j = 1 - i in
    Atomic.set flag.(i) true;
    Atomic.set victim i;
    while Atomic.get flag.(j) && Atomic.get victim = i do
      ()
    done

  let unlock () =
    let i = (Domain.self () :> int) - 1 in
    Atomic.set flag.(i) false
end

let counter = ref 0

let thread_work () =
  for _ = 1 to 1_000_000 do
    Peterson.lock ();
    incr counter;
    Peterson.unlock ()
  done

let () =
  Printf.printf "Testing Peterson's lock with 1_000_000 iterations per domain...\n%!";

  let d1 = Domain.spawn thread_work in
  let d2 = Domain.spawn thread_work in
  Domain.join d1;
  Domain.join d2;

  Printf.printf "Final counter value: %d (expected: 2_000_000)\n" !counter
