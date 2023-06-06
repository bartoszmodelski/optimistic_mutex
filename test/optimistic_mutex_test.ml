module Mutex = struct
  include Mutexlib.Optimistic_mutex

  let name = "Optimistic_mutex"
end

module Test = Standard_test.Test (Mutex)

let _ = Test.run ()
