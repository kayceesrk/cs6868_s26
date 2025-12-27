(** Lock-free queue - safe ONLY for Single Writer, Single Reader (SWSR)
    Based on Art of Multiprocessor Programming, Chapter 10
    This is the TwoThreadLockFreeQueue - works correctly only with
    one thread calling enq and one thread calling deq.

    NOT safe for multiple writers or multiple readers! *)

exception Full
exception Empty

type 'a t = {
  items : 'a option array;
  capacity : int;
  mutable head : int;  (* Modified only by dequeuer *)
  mutable tail : int;  (* Modified only by enqueuer *)
}

let create capacity =
  {
    items = Array.make capacity None;
    capacity;
    head = 0;
    tail = 0;
  }

(** Enqueue - should be called by only ONE thread *)
let enq q x =
  (* Check if queue is full *)
  if q.tail - q.head = q.capacity then
    raise Full;
  (* Write to the array *)
  q.items.(q.tail mod q.capacity) <- Some x;
  (* Advance tail *)
  q.tail <- q.tail + 1

(** Dequeue - should be called by only ONE thread *)
let deq q =
  (* Check if queue is empty *)
  if q.tail = q.head then
    raise Empty;
  (* Read from the array *)
  match q.items.(q.head mod q.capacity) with
  | None -> assert false  (* Should never happen *)
  | Some x ->
      (* Advance head *)
      q.head <- q.head + 1;
      x

(** Check if queue is empty *)
let is_empty q =
  q.tail = q.head

(** Check if queue is full *)
let is_full q =
  q.tail - q.head = q.capacity

(** Get current size *)
let size q =
  q.tail - q.head
