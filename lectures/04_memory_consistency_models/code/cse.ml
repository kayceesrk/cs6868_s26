let t1 a b =
  let r1 = !a * 2 in
  let r2 = !b in
  let r3 = !a * 2 in
  (r1, r2, r3)

let t2 b = b := 0

let main () =
  let ab = ref 1 in
  let h = Domain.spawn (fun _ ->
    let r1, r2, r3 = t1 ab ab in
    Printf.printf "r1 = %d, r2 = %d, r3 = %d\n" r1 r2 r3)
  in
  t2 ab;
  Domain.join h

let () = main ()