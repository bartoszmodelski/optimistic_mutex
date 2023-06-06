module Mutex = struct
  include Mutexlib.Ticket_spinlock

  let name = "Ticket_spinlock"
end

module Test = Standard_test.Test (Mutex)

let _ = Test.run ()
