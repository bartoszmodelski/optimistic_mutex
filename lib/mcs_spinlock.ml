type node = { locked : bool ref; next : next Atomic.t }
and next = Node of node | Nil

type t = next Atomic.t

let nil = Nil

let create () =
  Atomic.make (Node { locked = ref false; next = Atomic.make nil })

let lock (t : t) =
  let new_node = Node ({ locked = ref true; next = Atomic.make nil } : node) in
  let rec traverse_and_insert (({ locked; next } : node) as current) =
    match Atomic.get next with
    | Node actual_next -> traverse_and_insert actual_next
    | Nil ->
        if not (Atomic.compare_and_set next nil new_node) then
          traverse_and_insert current
        else
          while !locked do
            Domain.cpu_relax ()
          done
  in
  match Atomic.get t with
  | Nil -> assert false
  | Node hd -> traverse_and_insert hd

let unlock (t : t) =
  match Atomic.get t with
  | Nil -> assert false
  | Node { next; _ } -> (
      let next_val = Atomic.get next in
      Atomic.set t next_val;

      match next_val with
      | Nil -> assert false
      | Node { locked; _ } -> locked := false)
