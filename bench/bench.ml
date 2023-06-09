module type Intf = sig
  type t

  val create : unit -> t
  val lock : t -> unit
  val unlock : t -> unit
end

module Array_spinlock = struct
  include Mutexlib.Array_spinlock

  let create () = create ()
end

let implementations =
  [
    ("Stdlib.Mutex\t\t", (module Mutex : Intf));
    ("Mcs_spinlock\t\t", (module Mutexlib.Mcs_spinlock : Intf));
    ("Ticket_spinlock\t", (module Mutexlib.Ticket_spinlock : Intf));
    ("Array_spinlock\t\t", (module Array_spinlock : Intf));
    ("Optimistic_mutex\t", (module Mutexlib.Optimistic_mutex));
    ("Naive_spinlock\t\t", (module Mutexlib.Naive_spinlock));
  ]

let workload (type t) ~cycles ~barrier ~work_cycles
    (module Mutex : Intf with type t = t) (mutex : t) =
  Atomic.decr barrier;
  while Atomic.get barrier > 0 do
    Domain.cpu_relax ()
  done;
  let start_time = Unix.gettimeofday () in

  for _ = 1 to cycles do
    Mutex.lock mutex;
    for _ = 1 to work_cycles do
      Domain.cpu_relax ()
    done;
    Mutex.unlock mutex
  done;

  let end_time = Unix.gettimeofday () in
  let diff = end_time -. start_time in
  diff

let bench ~domains ~cycles ~work_cycles ~implementation =
  Gc.full_major ();
  let module Mutex = (val implementation : Intf) in
  let mutex = Mutex.create () in
  let barrier = Atomic.make domains in
  let domains_handles =
    List.init domains (fun _ ->
        Domain.spawn (fun () ->
            workload ~cycles ~barrier ~work_cycles (module Mutex) mutex))
  in
  let results = List.map Domain.join domains_handles in
  Stats.mean results

let run_single ~domains ~cycles ~work_cycles (name, implementation) =
  let data = Array.init 10 (fun _ -> -1.) in
  for i = 0 to 9 do
    let time = bench ~domains ~cycles ~work_cycles ~implementation in
    Array.set data i time
  done;
  let median = Stats.median (Array.to_list data) in
  let median_per_op = median /. Int.to_float cycles in
  let median_ns_per_op = median_per_op *. 1_000_000_000. in
  Printf.printf "[%s] time median: %.2f ns/op\n%!" name median_ns_per_op

let run domains cycles work_cycles =
  Printf.printf "\n%!";
  List.iter (run_single ~domains ~cycles ~work_cycles) implementations

open Cmdliner

let domains =
  let default = 1 in
  let info =
    Arg.info [ "d"; "domains" ] ~docv:"INT" ~doc:"Number of domains."
  in
  Arg.value (Arg.opt Arg.int default info)

let cycles =
  let default = 1_000_000 in
  let info =
    Arg.info [ "c"; "cycles" ] ~docv:"INT" ~doc:"Number of lock/unlock cycles."
  in
  Arg.value (Arg.opt Arg.int default info)

let work_cycles =
  let default = 0 in
  let info =
    Arg.info [ "w"; "work-cycles" ] ~docv:"INT"
      ~doc:"Number of work cycles per lock/unlock."
  in
  Arg.value (Arg.opt Arg.int default info)

let cmd =
  let open Term in
  const run $ domains $ cycles $ work_cycles

let () =
  exit @@ Cmd.eval
  @@ Cmd.v
       (Cmd.info ~doc:"Optimistic_mutex Benchmark" "optimistic_mutex_benchmark")
       cmd
