# Interface Specification (tracker task 0.4)

## Parameters
| Name | Allowed | Default | Meaning |
|---|---|---|---|
| N_QUBITS | 4, 5, 6 | 6 | state vector holds 2^N_QUBITS amplitudes |
| LANES | 1, 2, 4, 8 | 1 | amplitude pairs processed per cycle |
| DATA_WIDTH | >= 12 | 16 | bits per real / imag part (Q2.14 when 16) |
| PIPE_STAGES | 1..4 | 3 | pipeline depth of one lane |

## Top-level ports (`rtl/qsim_top.v`)
| Port | Dir | Width | Description |
|---|---|---|---|
| clk | in | 1 | clock, rising edge active |
| rst_n | in | 1 | synchronous active-low reset; state returns to \|0...0\| |
| instr_valid | in | 1 | instruction on `instr` is valid |
| instr | in | 32 | instruction word (format in docs/conventions.md) |
| ready | out | 1 | controller can accept an instruction |
| done | out | 1 | pulses 1 cycle when the accepted instruction has fully committed |
| rd_addr | in | N_QUBITS | amplitude read address (only when idle) |
| rd_re, rd_im | out | DATA_WIDTH | amplitude at `rd_addr` (combinational read) |
| err | out | 1 | sticky: illegal instruction (control == target, bad opcode, qubit >= N_QUBITS) |

## Handshake
1. `ready=1` and `instr_valid=1` on a rising edge -> instruction accepted, `ready` drops next cycle.
2. Controller runs: ISSUE pairs -> DRAIN pipeline -> COMMIT.
3. `done` pulses for one cycle, `ready` returns to 1 on the same cycle as `done`.
4. Back-to-back dependent gates are separated by a full drain (no overlap between gates).
5. Amplitude readout through `rd_addr` is only meaningful while `ready=1`.

## Reset behaviour
Reset during idle clears the state bank to \|0...0\| (amplitude 0x4000 + j0 at index 0) and clears `err`.
Reset during a running instruction is not supported and the state afterwards is undefined until the next reset.
