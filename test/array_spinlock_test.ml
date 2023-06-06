module Mutex = struct
  include Mutexlib.Array_spinlock

  let create () = create ()
  let name = "Array_spinlock"
end

module Test = Standard_test.Test (Mutex)

let _ = Test.run ()
