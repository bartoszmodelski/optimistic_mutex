type t = { sem : Semaphore.Binary.t; counter : int Atomic.t }

let create () =
  let counter = Atomic.make 0 in
  let sem = Semaphore.Binary.make false in
  { sem; counter }

let lock { sem; counter } =
  let index = Atomic.fetch_and_add counter 1 in
  assert (index >= 0);
  if index == 0 then () else Semaphore.Binary.acquire sem

let unlock { sem; counter } =
  let index = Atomic.fetch_and_add counter (-1) in
  if index <= 0 then failwith "mutex.unlock: not locked";
  if index == 1 then () else Semaphore.Binary.release sem

let try_lock { counter; _ } =
  Atomic.get counter == 0 && Atomic.compare_and_set counter 0 1

(*
  Further ideas:
  * Fenceless FAD - only need to emit a barrier if acquired the lock on quick path.
  * Don't use semaphore for parking and resuming domains.
  * "mutex" with timeout
*)


