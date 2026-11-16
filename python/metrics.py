"""Error metrics between a reference and a test state vector (tracker task 1.5).

Inputs are complex numpy arrays (convert fixed-point with fixed_point.to_complex).
"""
import numpy as np


def max_amp_error(ref, test):
    """Largest |ref_k - test_k| over all amplitudes."""
    return float(np.max(np.abs(np.asarray(ref) - np.asarray(test))))


def fidelity(ref, test):
    """|<ref|test>|^2 / (<ref|ref><test|test>), 1.0 means identical up to global phase."""
    ref, test = np.asarray(ref), np.asarray(test)
    num = abs(np.vdot(ref, test)) ** 2
    den = np.vdot(ref, ref).real * np.vdot(test, test).real
    return float(num / den)


def norm_drift(state):
    """| sum |amp|^2 - 1 |, should stay near 0 for a unitary circuit."""
    return float(abs(np.sum(np.abs(np.asarray(state)) ** 2) - 1.0))
