import math
import numpy as np
from fixedpoint import FixedPoint as fp

class Complex_fxp:
	real=None
	imag=None
	m = 32
	n = 32
	def __init__(self, real_value=0.0, imag_value=0.0, m_in=32, n_in=32):
		self.real = fp(real_value, signed=True, m = m_in, n=n_in, rounding ='convergent')
		self.imag = fp(imag_value, signed=True, m = m_in, n=n_in, rounding ='convergent')
		self.m=m_in
		self.n=n_in
	
	@classmethod
	def from_complex(cls, complex):
		return cls(complex.real, complex.imag)
		
	def resize(self, new_m, new_n):
		self.real.resize(new_m, new_n)
		self.imag.resize(new_m, new_n)
		self.m = new_m
		self.n = new_n
		
	def trim(self):
		self.real.trim()
		self.imag.trim()
		self.m = max(self.real.m, self.imag.m)
		self.n = max(self.real.n, self.imag.n)

	def conjugate(self):
		return Complex_fxp.from_complex(complex(self).conjugate())
        
	def __repr__(self):
		return f"Complex_fxp({float(self.real)}, {float(self.imag)}, Q{self.m}.{self.n})"
	
	def __add__(self, other):
		ret = complex(self) + complex(other)
		return Complex_fxp.from_complex(ret)

	def __radd__(self, other):
		ret = complex(self) + complex(other)
		return Complex_fxp.from_complex(ret)

	def __sub__(self, other):
		ret = complex(self) - complex(other)
		return Complex_fxp.from_complex(ret)

	def __rsub__(self, other):
		ret = complex(self) - complex(other)
		return Complex_fxp.from_complex(ret)
	
	def __mul__(self, other):
		ret = complex(self) * complex(other)
		return Complex_fxp.from_complex(ret)

	def __rmul__(self, other):
		ret = complex(self) * complex(other)
		return Complex_fxp.from_complex(ret)

	def __truediv__(self, other):
		ret = complex(self) / complex(other)
		return Complex_fxp.from_complex(ret)
	
	def __rtruediv__(self, other):
		ret = complex(self) / complex(other)
		return Complex_fxp.from_complex(ret)

	def __pow__(self, other):
		ret = complex(self) ** int(other)
		return Complex_fxp.from_complex(ret)
	
	def __iadd__(self, other):
		return self + other
	
	def __float__(self):
		return float(self.real)

	def __int__(self):
		return int(self.real)

	def __complex__(self):
		return complex(self.real, self.imag)

	def __eq__(self, other):
		return(self.real == other.real and self.imag == other.imag)

	def __abs__(self):
		return np.sqrt(float(self.real**2+self.imag**2))

	def __gt__(self, other):
		return np.abs(self) > np.abs(other)

