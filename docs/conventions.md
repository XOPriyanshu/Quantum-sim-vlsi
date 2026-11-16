# Design Conventions (fill in and freeze before writing RTL)

Both the Python fixed-point model and the RTL must follow exactly what is written here.

## Qubit indexing
- Little-endian: qubit q corresponds to bit q of the state index k.
- One-qubit gate on target q acts on pairs (i, j): j = i XOR (1 << q), bit q of i = 0.
- Pairs per one-qubit gate = 2^(n-1).

## Fixed-point format
- Stored amplitude: signed ___ bits (real) + signed ___ bits (imag)
- Fractional bits: ___
- How +1.0 is represented during initialization: ___
- Intermediate (wider) width for H and T sums: ___
- Rounding mode: ___
- Saturation: ___

## Constants
- Quantized 1/sqrt(2) = ___ (hex ___) - use the same value in Python and RTL

## Gate semantics
| Gate | Rule |
|---|---|
| H | (a,b) -> ((a+b)/sqrt2, (a-b)/sqrt2) |
| X | swap a,b |
| Z | negate amplitude where target bit = 1 |
| T | amplitude with target bit = 1 multiplied by (1+j)/sqrt2 |
| CNOT | control != target; swap pair only if control bit = 1 |
| MC phase flip | negate amplitude when (index & mask) == value; zero-controls supported: ___ |

## Instruction format
- Fields: opcode ___, target ___, control ___, mask ___, value ___
- Handshake: start/ready/done described in ___

## Parameters
- N_QUBITS (4/5/6), LANES (1/2/4/8), DATA_WIDTH, PIPE_STAGES
