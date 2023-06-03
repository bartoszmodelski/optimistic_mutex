let simple () =
  let mutex = Optimistic_mutex.create () in
  Optimistic_mutex.lock mutex;
  Optimistic_mutex.unlock mutex;
  Optimistic_mutex.lock mutex;
  Optimistic_mutex.unlock mutex

let second_domain_waits_f () =
  let mutex = Optimistic_mutex.create () in
  Optimistic_mutex.lock mutex;

  let ready = Atomic.make false in
  let in_critical_section = Atomic.make false in
  let domain =
    Domain.spawn (fun () ->
        Atomic.set ready true;
        Optimistic_mutex.lock mutex;
        Atomic.set in_critical_section true;
        Optimistic_mutex.unlock mutex)
  in
  while not (Atomic.get ready) do
    Domain.cpu_relax ()
  done;
  for _ = 1 to Random.int 1000 do
    Domain.cpu_relax ()
  done;

  assert (not (Atomic.get in_critical_section));

  Optimistic_mutex.unlock mutex;
  Domain.join domain;
  ()

let second_domain_waits () =
  for _ = 1 to 10_000 do
    second_domain_waits_f ()
  done

let multidomain_incr () =
  let domains = 4 in
  let barrier = Atomic.make domains in
  let cycles = 1_000_000 in
  let protected_var = ref 0 in
  let mutex = Optimistic_mutex.create () in

  let workload () =
    Atomic.decr barrier;
    while Atomic.get barrier > 0 do
      Domain.cpu_relax ()
    done;
    for _ = 1 to cycles do
      Optimistic_mutex.lock mutex;
      protected_var := !protected_var + 1;
      Optimistic_mutex.unlock mutex
    done
  in

  List.init domains (fun _ -> Domain.spawn workload)
  |> List.iter Domain.join;
  assert (!protected_var = domains * cycles)

let () =
  let open Alcotest in
  run "Optimistic_mutex"
    [
      ( "tests",
        [
          test_case "simple" `Quick simple;
          test_case "second domain waits" `Quick second_domain_waits;
          test_case "multidomain stress test" `Quick multidomain_incr;
        ] );
    ]
