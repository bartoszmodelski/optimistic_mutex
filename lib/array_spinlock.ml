type t = {
  waiters : int Atomic.t array;
  ticket : int Atomic.t;
  owner : int ref;
  mask : int;
  size_exp : int;
}

let create ?(size_exp = 8) () =
  let size = 1 lsl size_exp in
  let waiters = Array.init size (fun _ -> Atomic.make (-1)) in
  Atomic.set (Array.get waiters 0) 0;
  let ticket = Atomic.make 0 in
  let mask = size - 1 in
  { waiters; ticket; owner = ref 0; mask; size_exp }

let lock { waiters; ticket; owner; mask; size_exp } =
  let my = Atomic.fetch_and_add ticket 1 in
  let index = my land mask in
  let round = my lsr size_exp in
  let cell = Array.unsafe_get waiters index in
  while Atomic.get cell != round do
    Domain.cpu_relax ()
  done;
  owner := index

let unlock { waiters; owner; mask; _ } =
  let index = (!owner + 1) land mask in
  let round = Array.unsafe_get waiters index in
  (* Need this to be atomic to force barrier. It'd be nice if
     we could force it without doing an atomic. *)
  Atomic.incr round
