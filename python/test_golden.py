"""Analytical small-state tests for the golden model (tracker task 1.2)
and Grover reference test (task 1.3). Run: python3 -I python/test_golden.py
"""
import os, sys, unittest
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import golden as g
from grover_ref import grover_program, marked_probability

S = 1 / np.sqrt(2)


class TestGates(unittest.TestCase):
    def test_h_single(self):
        np.testing.assert_allclose(g.run_program(1, [("H", 0, 0, 0, 0)]), [S, S])

    def test_bell_state(self):
        psi = g.run_program(2, [("H", 0, 0, 0, 0), ("CNOT", 1, 0, 0, 0)])  # ctl=0, tgt=1
        np.testing.assert_allclose(psi, [S, 0, 0, S], atol=1e-12)

    def test_x_little_endian(self):
        psi = g.run_program(3, [("X", 2, 0, 0, 0)])
        self.assertAlmostEqual(abs(psi[0b100]), 1.0)

    def test_z_on_plus(self):
        psi = g.run_program(1, [("H", 0, 0, 0, 0), ("Z", 0, 0, 0, 0)])
        np.testing.assert_allclose(psi, [S, -S])

    def test_t_phase(self):
        psi = g.run_program(1, [("X", 0, 0, 0, 0), ("T", 0, 0, 0, 0)])
        np.testing.assert_allclose(psi, [0, (1 + 1j) * S])

    def test_cnot_no_flip_when_control_zero(self):
        psi = g.run_program(2, [("CNOT", 1, 0, 0, 0)])
        self.assertAlmostEqual(abs(psi[0]), 1.0)

    def test_cnot_same_qubit_rejected(self):
        with self.assertRaises(ValueError):
            g.apply_cnot(g.init_state(2), 2, 1, 1)

    def test_mcz_zero_controls(self):
        psi = g.run_program(2, [("H", 0, 0, 0, 0), ("H", 1, 0, 0, 0), ("MCZ", 0, 0, 0b11, 0b01)])
        np.testing.assert_allclose(psi, [0.5, -0.5, 0.5, 0.5])

    def test_unitarity_random_circuit(self):
        rng = np.random.default_rng(1)
        n, prog = 5, []
        for _ in range(60):
            op = ["H", "X", "Z", "T"][rng.integers(4)]
            prog.append((op, int(rng.integers(n)), 0, 0, 0))
        psi = g.run_program(n, prog)
        self.assertAlmostEqual(float(np.sum(abs(psi) ** 2)), 1.0, places=12)

    def test_pairs_unique_and_complete(self):
        for n in (4, 5, 6):
            for q in range(n):
                i, j = g.pair_indices(n, q)
                self.assertEqual(len(set(i) | set(j)), 1 << n)
                self.assertEqual(len(i), 1 << (n - 1))


class TestGrover(unittest.TestCase):
    def test_4_qubit_3_iterations(self):
        psi = g.run_program(4, grover_program(4, 0b1010, 3))
        self.assertAlmostEqual(marked_probability(psi, 0b1010), 0.9613, places=3)

    def test_any_marked_state(self):
        for m in range(16):
            psi = g.run_program(4, grover_program(4, m, 3))
            self.assertGreater(marked_probability(psi, m), 0.96)


if __name__ == "__main__":
    unittest.main(verbosity=2)
