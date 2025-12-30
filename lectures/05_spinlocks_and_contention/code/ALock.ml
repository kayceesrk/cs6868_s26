(* ALock.ml
 *
 * Array Lock (ALock) Implementation
 *
 * A queue-based lock where each thread spins on a different array element.
 * This eliminates the cache coherence traffic problem of simple spinlocks.
 *
 * How it works:
 * - Lock has an array of flags, one per potential thread
 * - Each flag is an atomic boolean indicating "it's your turn"
 * - Threads take a ticket (array index) using atomic increment
 * - Each thread spins ONLY on its own flag
 * - When unlocking, thread signals the next thread by setting its flag
 *
 * Why this is better:
 * - Each thread spins on a DIFFERENT memory location
 * - No cache coherence traffic while spinning
 * - Traffic only when passing the lock to next thread
 * - Use make_contended to prevent false sharing
 *
 * Performance characteristics:
 * - Excellent under high contention
 * - Better cache behavior than backoff lock
 * - Requires O(n) space for n threads
 * - Array size must be ≥ max number of concurrent threads
 *
 * False sharing prevention:
 * - Atomic.make_contended adds padding to each flag
 * - Prevents adjacent flags from sharing cache lines
 * - Critical for performance!
 *
 * Implementation notes:
 * - No allocations in lock/unlock path (critical for performance)
 * - Uses Domain.cpu_relax() while spinning
 * - Domain.DLS access is allocation-free
 *)

module ALock : sig
  include Lock.LOCK

  val create_with_capacity : int -> t
  (** Create an ALock with specified capacity (number of slots) *)
end = struct
  type t = {
    flags : bool Atomic.t array;
    tail : int Atomic.t;
    capacity : int;
    my_slot : int Domain.DLS.key;
  }

  let name = "Array Lock"

  let create_with_capacity capacity =
    if capacity <= 0 then
      invalid_arg "ALock capacity must be positive";

    (* Create array of atomic booleans using make_contended to prevent false sharing *)
    let flags =
      Array.init capacity (fun i ->
          (* Only slot 0 starts as true (available) *)
          Atomic.make_contended (i = 0))
    in

    {
      flags;
      tail = Atomic.make 0;
      capacity;
      my_slot = Domain.DLS.new_key (fun () -> -1);
    }

  (* Default capacity based on a reasonable number of domains *)
  (* Note: capacity should be close to the expected number of concurrent threads.
     If capacity >> threads, slots may never be properly initialized.
     If capacity < threads, some threads may have to wait longer. *)
  let create () = create_with_capacity 16

  let lock t =
    (* Get my slot using atomic fetch-and-increment *)
    let slot = (Atomic.fetch_and_add t.tail 1) mod t.capacity in

    (* Store slot in domain-local storage for unlock *)
    Domain.DLS.set t.my_slot slot;

    (* Cache the flag reference to avoid repeated array indexing *)
    let my_flag = t.flags.(slot) in

    (* Spin on MY flag until it becomes true *)
    (* This is the key: each thread spins on a DIFFERENT location *)
    while not (Atomic.get my_flag) do
      Domain.cpu_relax ()
    done

  let unlock t =
    (* Get my slot from domain-local storage *)
    let slot = Domain.DLS.get t.my_slot in

    if slot = -1 then
      failwith "unlock called without corresponding lock";

    (* Cache flag references *)
    let my_flag = t.flags.(slot) in
    let next_slot = (slot + 1) mod t.capacity in
    let next_flag = t.flags.(next_slot) in

    (* Clear my flag *)
    Atomic.set my_flag false;

    (* Signal the next thread *)
    Atomic.set next_flag true
end

(* Default ALock with standard capacity *)
module DefaultALock : Lock.LOCK = struct
  include ALock
  let create () = ALock.create ()
end
