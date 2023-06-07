type t = int
external make : unit -> t = "caml_suspend_resume_make"

external free : t -> unit = "caml_suspend_resume_free"


external wait : t -> unit = "caml_suspend_resume_wait"
external notify : t -> unit = "caml_suspend_resume_notify"
