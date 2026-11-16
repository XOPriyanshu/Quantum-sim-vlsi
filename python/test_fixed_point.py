"""Tests for the fixed-point model and metrics. Run: python3 -I python/test_fixed_point.py"""
import os, sys, unittest
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import golden as g
import fixed_point as fx
import metrics as m
from grover_ref import grover_program


class TestFixed(unittest.TestCase):
    def test_constant(self):
        self.assertEqual(fx.SQRT_HALF_Q, 0x2D41)
        self.assertEqual(fx.SQRT_HALF_Q, round(2 ** 14 / np.sqrt(2)))

    def test_init_is_one(self):
        re, im = fx.init_state(4)
        self.assertEqual((int(re[0]), int(im[0])), (0x4000, 0))
        self.assertEqual(int(np.abs(re[1:]).sum() + np.abs(im).sum()), 0)

    def test_rounding_half_up(self):
        self.assertEqual(int(fx.round_shift(np.int64(8192))), 1)    # +0.5 -> 1
        self.assertEqual(int(fx.round_shift(np.int64(-8192))), 0)   # -0.5 -> 0 (half-up)

    def test_saturation(self):
        self.assertEqual(int(fx.sat(np.int64(40000))), 32767)
        self.assertEqual(int(fx.sat(np.int64(-40000))), -32768)
        s = (np.array([-32768, 0]), np.array([0, 0]))
        fx.apply_z(s, 1, 0)
        self.assertEqual(int(s[0][1]), 0)
        s = (np.array([0, -32768]), np.array([0, 0]))
        fx.apply_z(s, 1, 0)
        self.assertEqual(int(s[0][1]), 32767)

    def test_matches_double_within_tolerance(self):
        prog = grover_program(4, 0b1010, 3)
        err = m.max_amp_error(g.run_program(4, prog), fx.to_complex(fx.run_program(4, prog)))
        self.assertLess(err, 5e-3)

    def test_metrics(self):
        a = np.array([1, 0], dtype=complex)
        self.assertAlmostEqual(m.fidelity(a, a * 1j), 1.0)          # global phase ignored
        self.assertAlmostEqual(m.fidelity(a, np.array([0, 1], dtype=complex)), 0.0)
        self.assertAlmostEqual(m.max_amp_error(a, a), 0.0)
        self.assertAlmostEqual(m.norm_drift(a * 1.1), 0.21, places=12)


if __name__ == "__main__":
    unittest.main(verbosity=2)
