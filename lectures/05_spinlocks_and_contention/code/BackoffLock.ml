(* BackoffLock.ml
 *
 * Backoff Lock Implementation
 *
 * An improvement over TTAS that adds exponential backoff when contention is detected.
 * When a thread fails to acquire the lock, it backs off for an increasing delay
 * before trying again. This reduces contention and cache coherence traffic.
 *
 * How it works:
 * - Spin-read until lock appears free (like TTAS)
 * - Try to acquire with atomic exchange
 * - If that fails, back off with exponentially increasing delay
 * - Use Domain.cpu_relax() for the backoff delay
 *
 * Why this is better than TTAS:
 * - Spreads out retry attempts, reducing cache coherence traffic
 * - Gives lock holder more time to complete critical section
 * - Exponential increase helps adapt to varying contention levels
 * - cpu_relax() is more efficient than busy waiting
 *
 * Performance characteristics:
 * - Best under high contention
 * - MIN_DELAY and MAX_DELAY need tuning for specific workloads
 * - Trade-off: too little backoff = high contention, too much = poor responsiveness
 *)

(* Backoff helper with exponential backoff using Domain.cpu_relax *)
module Backoff = struct
  type t = { min_delay : int; max_delay : int; mutable limit : int }

  let create min_delay max_delay = { min_delay; max_delay; limit = min_delay }

  let backoff t =
    (* Backoff for 'limit' iterations using cpu_relax *)
    for _ = 1 to t.limit do
      Domain.cpu_relax ()
    done;
    (* Exponentially increase the limit, capped at max_delay *)
    t.limit <- min t.max_delay (t.limit * 2)
end

(* Generic backoff lock that can be configured *)
module type BACKOFF_PARAMS = sig
  val min_delay : int
  val max_delay : int
end

module MakeBackoffLock (P : BACKOFF_PARAMS) : Lock.LOCK = struct
  type t = { state : bool Atomic.t }

  let name = Printf.sprintf "Backoff Lock (%d,%d)" P.min_delay P.max_delay

  let create () = { state = Atomic.make false }

  let lock t =
    let backoff = Backoff.create P.min_delay P.max_delay in
    (* Outer loop: keep trying until we get the lock *)
    while
      (* Inner loop: spin-read until lock appears free *)
      while Atomic.get t.state do
        ()
      done;

      (* Lock looks free, try to acquire *)
      Atomic.exchange t.state true
    do
      (* Failed to acquire - back off before trying again *)
      Backoff.backoff backoff
    done

  let unlock t = Atomic.set t.state false
end

(* Default backoff lock with standard parameters *)
module DefaultBackoffLock : Lock.LOCK = MakeBackoffLock (struct
  let min_delay = 1
  let max_delay = 256
end)

(* Helper to create custom backoff locks for benchmarking *)
let make_custom_lock min_delay max_delay =
  let module Params = struct
    let min_delay = min_delay
    let max_delay = max_delay
  end in
  (module MakeBackoffLock (Params) : Lock.LOCK)
