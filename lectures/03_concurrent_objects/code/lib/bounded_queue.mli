(** Simple bounded queue with a single lock - safe for Multiple Writers, Multiple Readers (MWMR) *)

(** Exception raised when trying to enqueue to a full queue *)
exception Full

(** Exception raised when trying to dequeue from an empty queue *)
exception Empty

(** The type of bounded queues containing elements of type ['a] *)
type 'a t

(** [create capacity] creates a new bounded queue with the given capacity *)
val create : int -> 'a t

(** [enq q x] adds element [x] to the tail of queue [q].
    @raise Full if the queue is already full *)
val enq : 'a t -> 'a -> unit

(** [deq q] removes and returns the element at the head of queue [q].
    @raise Empty if the queue is empty *)
val deq : 'a t -> 'a
