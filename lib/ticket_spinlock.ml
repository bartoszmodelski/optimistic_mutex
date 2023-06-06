type t = { owner : int Atomic.t; queue : int Atomic.t }

let create () =
  let owner = Atomic.make 0 in
  let queue = Atomic.make 0 in
  { owner; queue }

let lock { owner; queue } =
  let ticket = Atomic.fetch_and_add queue 1 in
  while Atomic.get owner != ticket do
    Domain.cpu_relax ()
  done

let unlock { owner; _ } =
  (* Owner does not have to be atomic, in theory.
     Would `Atomic.get queue` suffice to get a barrier? *)
  Atomic.incr owner
