type node = { locked : bool ref; next : next Atomic.t }
and next = Node of node | Nil

type t = { head : next Atomic.t Atomic.t; tail : next ref }

let nil = Nil

let create () =
  let next = Atomic.make nil in
  let head = Atomic.make next in
  let tail = ref (Node ({ locked = ref false; next } : node)) in
  { head; tail }

let lock ({ tail; _ } : t) =
  let new_node = Node ({ locked = ref true; next = Atomic.make nil } : node) in
  match !tail with
  | Nil -> assert false
  | Node node ->
      let rec traverse_and_insert (({ locked; next } : node) as current) =
        match Atomic.get next with
        | Node actual_next -> traverse_and_insert actual_next
        | Nil ->
            if not (Atomic.compare_and_set next nil new_node) then
              traverse_and_insert current
            else (
              tail := new_node;
              while !locked do
                Domain.cpu_relax ()
              done)
      in
      traverse_and_insert node

let unlock ({ head; _ } : t) =
  match Atomic.get (Atomic.get head) with
  | Nil -> assert false
  | Node { next; locked } ->
      Atomic.set head next;
      locked := false
