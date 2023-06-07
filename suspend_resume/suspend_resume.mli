type t

val make : unit -> t
val free : t -> unit
val wait : t -> unit
val notify : t -> unit
