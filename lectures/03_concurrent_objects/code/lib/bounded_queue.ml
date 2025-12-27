(** Simple bounded queue with a single lock - safe for Multiple Writers, Multiple Readers (MWMR) *)

exception Full
exception Empty

type 'a t = {
  items : 'a option array;
  capacity : int;
  mutable head : int;
  mutable tail : int;
  lock : Mutex.t;
}

let create capacity =
  {
    items = Array.make capacity None;
    capacity;
    head = 0;
    tail = 0;
    lock = Mutex.create ();
  }

let enq q x =
  Mutex.lock q.lock;
  try
    if q.tail - q.head = q.capacity then
      raise Full;
    q.items.(q.tail mod q.capacity) <- Some x;
    q.tail <- q.tail + 1;
    Mutex.unlock q.lock
  with e ->
    Mutex.unlock q.lock;
    raise e

let deq q =
  Mutex.lock q.lock;
  try
    if q.tail = q.head then
      raise Empty;
    match q.items.(q.head mod q.capacity) with
    | None -> assert false
    | Some x ->
        q.head <- q.head + 1;
        Mutex.unlock q.lock;
        x
  with e ->
    Mutex.unlock q.lock;
    raise e
