#!/usr/bin/env python3
"""Write a SYNTHETIC bitcoind debug.log (format modeled on Bitcoin Core v27 output) for the demo.
Deterministic (seeded). Not real node data. Usage: gen_bitcoind_log.py > debug.log"""
import random, datetime
r = random.Random(21); t = datetime.datetime(2026, 10, 1, 0, 0, 0)
h = 865000; peer = 0
def ts(): return t.strftime('%Y-%m-%dT%H:%M:%SZ')
for i in range(20000):
    t += datetime.timedelta(seconds=r.randint(1, 9)); x = r.random()
    if x < 0.55:
        h += 1; print(f"{ts()} UpdateTip: new best={r.getrandbits(256):064x} height={h} version=0x2{r.randint(0,9)}000000 log2_work=95.{r.randint(100000,999999)} tx={1100000000+h*3000} date='{ts()}' progress=1.000000 cache={r.randint(10,300)}.{r.randint(0,9)}MiB({r.randint(100000,2000000)}txo)")
    elif x < 0.80:
        peer += 1; print(f"{ts()} New outbound-full-relay v2 peer connected: version: 70016, blocks={h}, peer={peer}")
    elif x < 0.93:
        print(f"{ts()} Saw new header hash={r.getrandbits(256):064x} height={h+1}")
    elif x < 0.995:
        print(f"{ts()} [net] disconnecting peer={r.randint(1,peer+1)}")
    else:
        print(f"{ts()} ERROR: AcceptBlockHeader: block {r.getrandbits(256):064x} is marked invalid")
