#!/usr/bin/env python3
"""Generate independent expected outputs using existing python/fixed_point.py."""
import sys, random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'python'))
from fixed_point import mul_sqrt_half,sat
rng=random.Random(671)
output=ROOT/'tb'/'phase3_cases.txt'
def val(x): return int(x)
def neg(x): return val(sat(-x))
def scale(x): return val(mul_sqrt_half(x))
cases=[]
for op in range(6):
    for k in range(250):
        samples=[-32768,-32767,-16384,-1,0,1,16384,32766,32767]
        a,b,c,d=[rng.choice(samples) if k<50 else rng.randint(-32768,32767) for _ in range(4)]
        swap=rng.randint(0,1); fa=rng.randint(0,1); fb=rng.randint(0,1)
        if op==0: expected=(scale(a+c),scale(b+d),scale(a-c),scale(b-d))
        elif op==1: expected=(c,d,a,b)
        elif op==2: expected=(a,b,neg(c),neg(d))
        elif op==3: expected=(a,b,scale(c-d),scale(c+d))
        elif op==4: expected=(c,d,a,b) if swap else (a,b,c,d)
        else: expected=(neg(a) if fa else a,neg(b) if fa else b,neg(c) if fb else c,neg(d) if fb else d)
        cases.append((op,swap,fa,fb,a,b,c,d,*expected))
with output.open('w') as f:
    for case in cases: f.write(' '.join(map(str,case))+'\n')
print(f'Generated {len(cases)} cases: {output}')
