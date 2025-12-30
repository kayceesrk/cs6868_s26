(* TASLock.ml
 *
 * Test-And-Set Lock Implementation
 *
 * This is the simplest spinlock implementation using atomic test-and-set.
 * It uses a single atomic boolean variable to represent the lock state.
 *
 * How it works:
 * - lock(): Keep trying to atomically set the state to true until successful
 * - unlock(): Set the state back to false
 *
 * Performance characteristics:
 * - Simple but can cause high cache coherence traffic
 * - Every spinning thread continuously performs atomic operations
 * - This invalidates other threads' caches on every test-and-set
 *)

module TASLock : Lock.LOCK = struct
  type t = { state : bool Atomic.t }

  let name = "TAS Lock"

  let create () = { state = Atomic.make false }

  let lock t =
    (* Keep spinning until we successfully acquire the lock *)
    (* Atomic.exchange sets the value and returns the old value *)
    while Atomic.exchange t.state true do
      (* Spin - this is where the thread wastes CPU cycles *)
      ()
    done

  let unlock t = Atomic.set t.state false
end
