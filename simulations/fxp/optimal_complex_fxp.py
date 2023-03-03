import math
import numpy as np
from complex_fxp import Complex_fxp as cfxp

class Optimal_Complex_FXP:
    cfxp_number = None
    complex_number = None
    m = None
    n = None
    sqnr = None
    def __init__(self, real = 0.0, imag=0.0, m_in=32, n_in=32):
        self.cfxp_number = cfxp(real, imag, m_in, n_in)
        self.complex_number = complex(real, imag)
        self.m = m_in
        self.n = n_in

    @classmethod
    def from_Complex(cls, complex, m, n):
        return cls(complex.real, complex.imag, m, n)

    def sqnr(self) -> float:
        quant_err = self.complex_number - self.cfxp_number
        p_noise = float(np.sum(np.abs(quant_err) ** 2))
        p_signal = float(np.sum(np.abs(self.complex_number) ** 2)) 
        sqnr = 10*np.log10(p_signal/p_noise)
        return sqnr

    def conjugate(self):
        self.complex_number = self.complex_number.conjugate()
        self.cfxp_number = self.cfxp_number.conjugate()
        return self

    def __repr__(self):
        return f"complex({self.complex_number}), fxp({self.cfxp_number})"

    def __add__(self, other):
        complex_value = self.complex_number + other.complex_number
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __radd__(self, other):
        other_complex = complex(other)
        complex_value = self.complex_number + other_complex
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __sub__(self, other):
        complex_value = self.complex_number - other.complex_number
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __rsub__(self, other):
        other_complex = complex(other)
        complex_value = self.complex_number - other_complex
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __mul__(self, other):
        complex_value = self.complex_number * other.complex_number
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __rmul__(self, other):
        other_complex = complex(other)
        complex_value = self.complex_number * other_complex
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __truediv__(self, other):
        complex_value = self.complex_number / other.complex_number
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __rtruediv__(self, other):
        other_complex = complex(other)
        complex_value = self.complex_number / other_complex
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __pow__(self, other):
        complex_value = self.complex_number ** other.complex_number
        return Optimal_Complex_FXP.from_Complex(complex_value, self.m, self.n)

    def __iadd__(self, other):
        return self + other

    def __float__(self):
        return self.complex_number.real
        
    def __int__(self):
        return int(self.complex_number.real)
        
    def __complex__(self):
        return self.complex_number

    def __eq__(self, other):
        return (self.cfxp_number == other.cfxp_number)

    def __abs__(self):
        return np.abs(self.complex_number)

    def __gt__(self, other):
        return (np.abs(self.complex_number) > np.abs(other))