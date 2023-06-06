module Mutex = struct
  include Mutexlib.Mcs_spinlock

  let name = "Mcs_spinlock"
end

module Test = Standard_test.Test (Mutex)

let _ = Test.run ()
