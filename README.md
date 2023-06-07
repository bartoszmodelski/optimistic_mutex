# Mutexlib

A menagerie of locks for all occassions.

- [Optimistic_mutex](lib/optimistic_mutex.ml)- a wrapper for `Stdlib.Mutex`, which skips the call into
  `pthreads`, when the mutex is available. Tends to be 60-65% faster than
  `Stdlib.Mutex` on a single-core benchmark. If there's contention, it falls
  back onto standard library's conditional variable to avoid spinning (and
  that's more costly).
- [Ticket_spinlock](lib/ticket_spinlock.ml) - a simple ticket spinlock with two atomic variables (hence
  less contention but no `try_lock` function). Performs surprisingly well.
- [Mcs_spinlock](lib/mcs_spinlock.ml) - a classic lock based on a linked list, that lets all waiters
  spin on disjoint memory regions. Generally disappointing. Tends to be the
  worst of all locks on longer benchmark (I suspect GC). It dominates other only
  very specific workloads (e.g. ultra-overcommited ones or very bursty).
- [Array_spinlock](lib/array_spinlock.ml) - similar story to Mcs, although tends to be a bit better in
  the average case.
- [Naive_spinlock](lib/naive_spinlock.ml) - well, naive spinlock.

# Benchmarks

Some benchmarks highlighting strengths and weaknesses of the structures in this
repo. You should probably read these carefully if you plan to replace
`Stdlib.Mutex` with something else.

All benchmarks have been done on x86.

## Basic lock&unlock

Single domain.

```
./_build/default/bench/bench.exe -d 1
[Stdlib.Mutex           ] time median: 16.53 ns/op
[Mcs_spinlock           ] time median: 64.94 ns/op
[Ticket_spinlock        ] time median: 6.27 ns/op
[Array_spinlock         ] time median: 6.86 ns/op
[Optimistic_mutex       ] time median: 5.77 ns/op
[Naive_spinlock         ] time median: 7.85 ns/op
```

Optimistic case. Most implementations are significantly faster than the standard
library. Exception being `Mcs_spinlocks`. Seems that the extra allocations tip
the scale. I have not investigated much as with the 256-domain lock
`Array_spinlock` provides pretty much the same benefits.

## Lock&unlock under contention

Two domains.

```
./_build/default/bench/bench.exe -d 2
[Stdlib.Mutex           ] time median: 95.14 ns/op
[Mcs_spinlock           ] time median: 165.07 ns/op
[Ticket_spinlock        ] time median: 64.45 ns/op
[Array_spinlock         ] time median: 146.82 ns/op
[Optimistic_mutex       ] time median: 167.49 ns/op
[Naive_spinlock         ] time median: 62.55 ns/op
```

`Optimistic_mutex` drops off as the chances of hitting fast path are small, and
there's the extra cost of trying it and two mutex cycles due to conditional
variable.

It's a bit surprising that `Array_spinlock` loses this much in comparison with
`Ticket_spinlock`.

## Lock&unlock under heavy contention

Three domains.

```
./_build/default/bench/bench.exe -d 3
[Stdlib.Mutex           ] time median: 146.76 ns/op
[Mcs_spinlock           ] time median: 459.69 ns/op
[Ticket_spinlock        ] time median: 231.27 ns/op
[Array_spinlock         ] time median: 265.67 ns/op
[Optimistic_mutex       ] time median: 315.90 ns/op
[Naive_spinlock         ] time median: 174.12 ns/op
```

I suspect that we start seeing that spinlocks cannot wake each other up. All of
the non-naive spinlocks are fair, and if a domain in line is suspended, everyone
waits while scheduler rolls the dice. Thus, despite massive contention,
`Naive_spinlock` is the one that fares to `Stdlib.Mutex`.

Suspend/resume mechanism would help both approaches: the fair implementation may
force wake the domain in line, while naive may put some to sleep to manage
contention better.

## Heavily overcommited workload

32 domains (on 16-core processor), lock&unlock x100.

```
./_build/default/bench/bench.exe -d 32 -c 100
[Stdlib.Mutex           ] time median: 166165.72 ns/op
[Optimistic_mutex       ] time median: 462070.82 ns/op
[Mcs_spinlock           ] time median: 5280.67 ns/op
[Ticket_spinlock        ] time median: 6665.81 ns/op
[Array_spinlock         ] time median: 4301.18 ns/op
```

Spinlocks perform well in such a scenario. Presumably because critical section
is nonexistent and the cost of suspending and resuming threads outweighs the
benefits.

## Longer critical section

Why not spinlock all the things then?

4 domains, each cycle does 5000 units of work (a single unit on a single core
takes around 20ns).

```
./_build/default/bench/bench.exe -d 4 -c 1000 -w 5000
[Stdlib.Mutex           ] time median: 251305.88 ns/op
[Optimistic_mutex       ] time median: 250947.59 ns/op
[Mcs_spinlock           ] time median: 412627.22 ns/op
[Ticket_spinlock        ] time median: 414631.16 ns/op
[Array_spinlock         ] time median: 418065.67 ns/op
```

As soon as we add some work in the critical section and there's contention,
spinlocks' performance tanks. That's because OS may is more likely to suspend
domain inside critical section, and does not know that others cannot make
progress. It's much less of a problem if other waiters are not competing for
CPU.

Note, the above benchmark is still somewhat well-behaved because there's more
free CPU cores than domains. For some strongly overcommited workloads spinlocks
degrade far further (e.g. 10-20x slower).

# Contributions

Contributions are welcome. For some ideas, it'd be nice to have:

- `RWLock` (e.g. just using the `pthreads` one). They are super useful in a lot
  of backend work.
- Lower-level thread suspend/resume primitives, like
  [here](https://github.com/pitdicker/valet_parking). These would let us build
  locks that are both faster than stdlib's mutex and reliable.

# Install

`opam pin add optimistic_mutex git@github.com:bartoszmodelski/optimistic_mutex.git`
