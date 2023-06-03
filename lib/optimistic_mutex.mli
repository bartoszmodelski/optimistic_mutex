(** Documentation mostly copied from the standard library. *)

type t
(** The type of mutexes. *)

val create : unit -> t
(** Return a new mutex. *)

val lock : t -> unit
(** Lock the given mutex. Only one thread can have the mutex locked
   at any time. A thread that attempts to lock a mutex already locked
   by another thread will suspend until the other thread unlocks
   the mutex.

   @raise Sys_error if the mutex is already locked by the thread calling
   {!Mutex.lock}. *)

val unlock : t -> unit
(** Unlock the given mutex. Other threads suspended trying to lock
   the mutex will restart.  The mutex must have been previously locked
   by the thread that calls {!Mutex.unlock}.
   @raise Sys_error if the mutex is unlocked or was locked by another thread. *)
