(** Lock-free queue - safe ONLY for Single Writer, Single Reader (SWSR)

    This queue uses no locks and is only safe when:
    - Exactly ONE thread calls enq
    - Exactly ONE thread calls deq

    NOT safe for multiple writers or multiple readers! *)

(** Exception raised when trying to enqueue to a full queue *)
exception Full

(** Exception raised when trying to dequeue from an empty queue *)
exception Empty

(** The type of lock-free queues containing elements of type ['a] *)
type 'a t

(** [create capacity] creates a new lock-free queue with the given capacity *)
val create : int -> 'a t

(** [enq q x] adds element [x] to the tail of queue [q].
    WARNING: Only call from a single thread!
    @raise Full if the queue is already full *)
val enq : 'a t -> 'a -> unit

(** [deq q] removes and returns the element at the head of queue [q].
    WARNING: Only call from a single thread!
    @raise Empty if the queue is empty *)
val deq : 'a t -> 'a

(** [is_empty q] returns true if the queue is empty *)
val is_empty : 'a t -> bool

(** [is_full q] returns true if the queue is full *)
val is_full : 'a t -> bool

(** [size q] returns the current number of elements in the queue *)
val size : 'a t -> int
