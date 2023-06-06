module Mutex = struct
  include Mutexlib.Naive_spinlock

  let name = "Naive_spinlock"
end

module Test = Standard_test.Test (Mutex)

let _ = Test.run ()
