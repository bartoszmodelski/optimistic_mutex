# Optimistic Mutex

A wrapper for `Stdlib.Mutex`, which skips the call into `pthreads` when mutex is
available. See the benchmark (x86):

```
$ dune exec -- bench/bench.exe --domains 1 --cycles 1000000
[Stdlib.Mutex           ] time median: 15.71 ns/op
[Optimistic_mutex       ] time median: 6.65 ns/op
```

In the optimistic case, `Optimistic_mutex` requires one atomic operation to
acquire a lock and another one to release it. If there's contention, it falls
back onto conditional variable from the standard library and that is costlier
than `pthread` mutex alone.

```
$ dune exec -- bench/bench.exe --domains 2 --cycles 1000000
[Stdlib.Mutex           ] time median: 95.66 ns/op
Optimistic_mutex     ] time median: 185.85 ns/op
$ dune exec -- bench/bench.exe --domains 3 --cycles 1000000
[Stdlib.Mutex           ] time median: 172.30 ns/op
[Optimistic_mutex       ] time median: 360.81 ns/op
```

# Install

`opam pin add optimistic_mutex git@github.com:bartoszmodelski/optimistic_mutex.git`
