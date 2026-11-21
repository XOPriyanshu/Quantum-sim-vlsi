
#!/usr/bin/env python3
"""Generate deterministic Phase 4 programs and expected final Q2.14 states."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))

from fixed_point import init_state, apply_instr


# Opcodes from docs/conventions.md
# H=0, X=1, Z=2, T=3, CNOT=4, MCZ=5

def encode(op, target=0, control=0, mask=0, value=0):
    return (
        ((value & 0x3F) << 15)
        | ((mask & 0x3F) << 9)
        | ((control & 7) << 6)
        | ((target & 7) << 3)
        | (op & 7)
    )


def program_for(n):
    # Little-endian qubit indexing
    p = [
        ("H", 0, 0, 0, 0),
        ("H", 1, 0, 0, 0),
        ("T", 2, 0, 0, 0),
        ("CNOT", 2, 0, 0, 0),
        ("X", 3, 0, 0, 0),
        ("Z", 1, 0, 0, 0),
        ("MCZ", 0, 0, 0b000101, 0b000001),
        ("H", 3, 0, 0, 0),
        ("T", 0, 0, 0, 0),
        ("CNOT", 1, 2, 0, 0),
        ("MCZ", 0, 0, 0b000111, 0b000101),
    ]

    if n >= 5:
        p.extend([
            ("H", 4, 0, 0, 0),
            ("X", 4, 0, 0, 0),
        ])

    if n >= 6:
        p.extend([
            ("T", 5, 0, 0, 0),
            ("Z", 5, 0, 0, 0),
        ])

    return p


OP = {
    "H": 0,
    "X": 1,
    "Z": 2,
    "T": 3,
    "CNOT": 4,
    "MCZ": 5,
}


# Generate programs for 4, 5 and 6 qubits
for n in (4, 5, 6):

    program = program_for(n)
    state = init_state(n)
    words = []

    # Execute instructions using Python reference
    for op, target, control, mask, value in program:
        apply_instr(
            state,
            n,
            (op, target, control, mask, value)
        )

        words.append(
            encode(OP[op], target, control, mask, value)
        )

    # Store instruction count followed by instructions
    instr_lines = [f"{len(words):08x}"]

    instr_lines.extend(
        f"{w:08x}" for w in words
    )

    # Pad memory to 17 entries (0 through 16)
    MAX_MEM_ENTRIES = 17

    if len(instr_lines) > MAX_MEM_ENTRIES:
        raise ValueError(
            f"Program for N={n} exceeds instruction memory"
        )

    instr_lines.extend(
        ["00000000"] * (MAX_MEM_ENTRIES - len(instr_lines))
    )

    # Write instruction memory file
    (ROOT / f"tb/phase4_instr_n{n}.hex").write_text(
        "\n".join(instr_lines) + "\n",
        encoding="ascii"
    )

    # Extract expected real and imaginary amplitudes
    re, im = state

    # Write expected real amplitudes
    (ROOT / f"tb/phase4_expected_re_n{n}.hex").write_text(
        "".join(
            f"{int(v) & 0xffff:04x}\n" for v in re
        ),
        encoding="ascii"
    )

    # Write expected imaginary amplitudes
    (ROOT / f"tb/phase4_expected_im_n{n}.hex").write_text(
        "".join(
            f"{int(v) & 0xffff:04x}\n" for v in im
        ),
        encoding="ascii"
    )

    print(
        f"Generated N={n}: "
        f"{len(words)} instructions, "
        f"{1 << n} expected amplitudes"
    )


print("Phase 4 scoreboard reference files generated.")
