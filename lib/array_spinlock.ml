type t = {
  waiters : int Atomic.t array;
  ticket : int Atomic.t;
  owner : int ref;
}

let create ?(size = 256) () =
  let waiters = Array.init size (fun _ -> Atomic.make (-1)) in
  Atomic.set (Array.get waiters 0) 0;
  let ticket = Atomic.make 0 in
  { waiters; ticket; owner = ref 0 }

let lock { waiters; ticket; owner } =
  let my = Atomic.fetch_and_add ticket 1 in
  let length = Array.length waiters in
  let index = my mod length in
  let round = my / length in
  while Atomic.get (Array.get waiters index) != round do
    Domain.cpu_relax ()
  done;
  owner := index

let unlock { waiters; owner; _ } =
  let index = (!owner + 1) mod Array.length waiters in
  let round = Array.get waiters index in
  Atomic.incr round
