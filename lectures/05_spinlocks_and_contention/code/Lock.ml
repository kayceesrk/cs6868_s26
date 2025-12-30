(* Lock.ml
 *
 * Common lock interface for all spinlock implementations
 *)

module type LOCK = sig
  type t

  val create : unit -> t
  (** Create a new lock instance *)

  val lock : t -> unit
  (** Acquire the lock, spinning until successful *)

  val unlock : t -> unit
  (** Release the lock *)

  val name : string
  (** Name of the lock implementation for display *)
end
