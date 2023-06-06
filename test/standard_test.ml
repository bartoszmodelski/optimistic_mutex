module type Intf = sig
  type t

  val create : unit -> t
  val lock : t -> unit
  val unlock : t -> unit
  val name : String.t
end

module Test (Mutex : Intf) = struct
  let simple () =
    let mutex = Mutex.create () in
    Mutex.lock mutex;
    Mutex.unlock mutex;
    Mutex.lock mutex;
    Mutex.unlock mutex

  let second_domain_waits_f () =
    let mutex = Mutex.create () in
    Mutex.lock mutex;

    let ready = Atomic.make false in
    let in_critical_section = Atomic.make false in
    let domain =
      Domain.spawn (fun () ->
          Atomic.set ready true;
          Mutex.lock mutex;
          Atomic.set in_critical_section true;
          Mutex.unlock mutex)
    in
    while not (Atomic.get ready) do
      Domain.cpu_relax ()
    done;
    for _ = 1 to Random.int 1000 do
      Domain.cpu_relax ()
    done;

    assert (not (Atomic.get in_critical_section));

    Mutex.unlock mutex;
    Domain.join domain;
    ()

  let second_domain_waits () =
    for _ = 1 to 10_000 do
      second_domain_waits_f ()
    done

  let multidomain_incr () =
    let domains = 4 in
    let barrier = Atomic.make domains in
    let cycles = 100_000 in
    let protected_var = ref 0 in
    let mutex = Mutex.create () in

    let workload () =
      Atomic.decr barrier;
      while Atomic.get barrier > 0 do
        Domain.cpu_relax ()
      done;
      for _ = 1 to cycles do
        Mutex.lock mutex;
        protected_var := !protected_var + 1;
        Mutex.unlock mutex
      done
    in

    List.init domains (fun _ -> Domain.spawn workload) |> List.iter Domain.join;
    assert (!protected_var = domains * cycles)

  let run () =
    let open Alcotest in
    run Mutex.name
      [
        ( "tests",
          [
            test_case "simple" `Quick simple;
            test_case "second domain waits" `Quick second_domain_waits;
            test_case "multidomain stress test" `Slow multidomain_incr;
          ] );
      ]

end
