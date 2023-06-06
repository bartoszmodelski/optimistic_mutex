(* This should not be used in production. *)
type t

val create : ?size:int -> unit -> t
val lock : t -> unit
val unlock : t -> unit
