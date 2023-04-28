import math
import numpy as np
import matplotlib.pyplot as plt
import commpy.filters as filter
from fixedpoint import FixedPoint as fp
import statistics

sps = 8 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps
num_symbols = 43
beta = 0.5
rrc_taps=43

#same imput from firFXP 
x = np.zeros(num_symbols)
x[0] = 1

_, h_rrc = filter.rrcosfilter(rrc_taps, beta, Tsymbol, fsamples)

x_shaped = np.convolve(x, h_rrc)

print(h_rrc)
print(x_shaped)