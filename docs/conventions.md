# Design Conventions (FROZEN - tracker task 0.3)

Both the Python fixed-point model and the RTL must follow exactly what is written here.

## Qubit indexing
- Little-endian: qubit q corresponds to bit q of the state index k.
- One-qubit gate on target q acts on pairs (i, j): j = i XOR (1 << q), bit q of i = 0.
- Pairs per one-qubit gate = 2^(n-1).

## Fixed-point format
- Stored amplitude: signed 16 bits (real) + signed 16 bits (imag), two's complement
- Format: Q2.14 -> 14 fractional bits, range [-2.0, 2.0)
- How +1.0 is represented during initialization: 0x4000 (real), 0x0000 (imag) at index 0; all other amplitudes 0
- Intermediate (wider) width for H and T sums: 18 bits signed for the add/subtract, 34 bits signed after multiplying by the 1/sqrt(2) constant
- Rounding mode: round-half-up (add 1<<13, arithmetic shift right by 14)
- Saturation: clamp to [-32768, 32767] after rounding (never wrap)

## Constants
- Quantized 1/sqrt(2) = 11585 / 16384 = 0.70709229 (hex 0x2D41) - use the same value in Python and RTL

## Gate semantics
| Gate | Rule |
|---|---|
| H | (a,b) -> ((a+b)/sqrt2, (a-b)/sqrt2) |
| X | swap a,b |
| Z | negate amplitude where target bit = 1 |
| T | amplitude with target bit = 1 multiplied by (1+j)/sqrt2 (this is the project's "T"; it is the pi/4 phase gate times e^{i pi/4}, i.e. exp(i*pi/4) on |1>) |
| CNOT | control != target; swap pair only if control bit = 1 |
| MC phase flip | negate amplitude when (index & mask) == value; zero-controls supported: YES (value selects which mask bits must be 0 and which must be 1; value & ~mask must be 0) |

Note on negation: negating -32768 saturates to +32767.

## Instruction format (32-bit word, see docs/interface_spec.md)
- Fields: opcode [2:0], target [5:3], control [8:6], mask [14:9], value [20:15], bits [31:21] reserved (0)
- Opcodes: 0=H 1=X 2=Z 3=T 4=CNOT 5=MCZ (multi-controlled phase flip)
- Handshake: start/ready/done described in docs/interface_spec.md

## Parameters
- N_QUBITS (4/5/6), LANES (1/2/4/8), DATA_WIDTH (default 16), PIPE_STAGES (default 3)
