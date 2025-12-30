(* TTASLock.ml
 *
 * Test-Test-And-Set Lock Implementation
 *
 * This is an improved version of TAS lock that reduces cache coherence traffic.
 * The key insight: read the lock state before attempting to acquire it.
 *
 * How it works:
 * - First loop: Keep reading (testing) until lock appears free
 * - Then try atomic exchange (test-and-set)
 * - If that fails, go back to reading
 *
 * Why this is better than TAS:
 * - Reading is cheaper than atomic operations
 * - Atomic operations invalidate other caches
 * - By reading first, we only do expensive atomic ops when lock might be free
 * - Reduces cache coherence traffic significantly under contention
 *
 * Performance characteristics:
 * - Better than TAS under moderate to high contention
 * - Reads don't generate coherence traffic (cache can be shared)
 * - Only generates traffic when lock is released and threads compete
 *)

module TTASLock : Lock.LOCK = struct
  type t = { state : bool Atomic.t }

  let name = "TTAS Lock"

  let create () = { state = Atomic.make false }

  let lock t =
    (* Outer loop: keep trying until we get the lock *)
    while
      (* Inner loop: spin-read until lock appears free *)
      (* This is cheap - just reading, no cache invalidation *)
      while Atomic.get t.state do
        ()
      done;

      (* Lock looks free, try to acquire with atomic exchange *)
      (* exchange returns the OLD value:
         - false means lock was free, we got it -> return false to exit while
         - true means someone grabbed it first -> return true to continue while *)
      Atomic.exchange t.state true
    do
      (* If we're here, exchange returned true (lock was taken) *)
      (* Go back to spin-reading *)
      ()
    done
    (* If we exit the while loop, exchange returned false - we have the lock! *)

  let unlock t = Atomic.set t.state false
end
