(* Producer-Consumer with Alice and Bob using Can Protocol *)

(* Different types of fish *)
type fish = Salmon | Trout | Bass | Catfish | Tuna

let fish_to_string = function
  | Salmon -> "Salmon"
  | Trout -> "Trout"
  | Bass -> "Bass"
  | Catfish -> "Catfish"
  | Tuna -> "Tuna"

let random_fish () =
  match Random.int 5 with
  | 0 -> Salmon
  | 1 -> Trout
  | 2 -> Bass
  | 3 -> Catfish
  | _ -> Tuna

(* Can state for synchronization *)
type can_state = Up | Down

type can = { mutable state : can_state; mutex : Mutex.t }

let create_can () = { state = Up; mutex = Mutex.create () }

let is_up can =
  Mutex.lock can.mutex;
  let result = can.state = Up in
  Mutex.unlock can.mutex;
  result

let is_down can =
  Mutex.lock can.mutex;
  let result = can.state = Down in
  Mutex.unlock can.mutex;
  result

let reset can =
  Mutex.lock can.mutex;
  can.state <- Up;
  Mutex.unlock can.mutex

let knock_over can =
  Mutex.lock can.mutex;
  can.state <- Down;
  Mutex.unlock can.mutex

(* Shared pond with current fish *)
type pond = { mutable food : fish option; mutex : Mutex.t }

let create_pond () = { food = None; mutex = Mutex.create () }

let stock_pond pond fish =
  Mutex.lock pond.mutex;
  pond.food <- Some fish;
  Mutex.unlock pond.mutex

let get_food pond =
  Mutex.lock pond.mutex;
  let food = pond.food in
  Mutex.unlock pond.mutex;
  food

(* Alice (Consumer) - releases pets to eat fish *)
let alice can pond =
  while true do
    while is_up can do
      ()
    done;
    (match get_food pond with
    | Some fish ->
        Printf.printf "Alice: Releasing pets to eat %s\n%!" (fish_to_string fish);
        Unix.sleepf 0.1;
        Printf.printf "Alice: Recapturing pets\n%!"
    | None -> ());
    reset can
  done

(* Bob (Producer) - stocks the pond with fish *)
let bob can pond =
  while true do
    while is_down can do
      ()
    done;
    let fish = random_fish () in
    Printf.printf "Bob: Stocking pond with %s\n%!" (fish_to_string fish);
    stock_pond pond fish;
    knock_over can
  done

(* Main program *)
let () =
  Random.self_init ();
  let can = create_can () in
  let pond = create_pond () in
  Printf.printf "Starting Producer-Consumer with Can Protocol...\n%!";
  Printf.printf "Bob produces fish, Alice's pets consume them.\n\n%!";
  (* Spawn Alice's domain (consumer) *)
  let alice_domain = Domain.spawn (fun () -> alice can pond) in
  (* Spawn Bob's domain (producer) *)
  let bob_domain = Domain.spawn (fun () -> bob can pond) in
  (* Let them run for a bit *)
  Unix.sleep 5;
  (* Note: In a real program, we'd need a way to stop them gracefully *)
  Domain.join alice_domain;
  Domain.join bob_domain
