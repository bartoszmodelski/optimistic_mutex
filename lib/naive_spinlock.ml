type t = bool Atomic.t

let create () = Atomic.make false

let lock t =
  while not (Atomic.compare_and_set t false true) do
    Domain.cpu_relax ()
  done

let unlock t = Atomic.set t false
