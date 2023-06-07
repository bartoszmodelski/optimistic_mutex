let _ =
  let s = Suspend_resume.make () in
  Domain.spawn (fun () ->
    Unix.sleepf 0.1;
    Suspend_resume.notify s) |> ignore;
  Suspend_resume.wait s;
  Suspend_resume.free s;
  Printf.printf "success\n%!"
