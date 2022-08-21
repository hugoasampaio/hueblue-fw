import math
import numpy as np
import matplotlib.pyplot as plt
import commpy.filters as filter
from fixedpoint import FixedPoint as fp
import statistics

class qpsk_tx:
    sps = 8
    fsamples = 1 # assume our sample rate is 1 Hz
    Tsample = 1/fsamples # calc sample period
    Tsymbol = Tsample*sps

    def __init__(self, bins = 50, srrc_taps = 43, beta = 0.50):
        num_symbols = int(bins*self.fsamples)

        in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

        x = np.array([])
        for bit in in_bits:
            pulse = np.zeros(sps)
            pulse[0] = bit*2-1 # set the first value to either a 1 or -1
            x = np.concatenate((x, pulse)) # add the 8 samples to the signal

        _, hsrrc = filter.rrcosfilter(srrc_taps, beta, self.Tsymbol, self.fsamples)

        hsrrc_fp = []
        for a in hsrrc:
            hsrrc_fp.append(fp(a, signed=1, m=2, n=8, rounding='convergent'))
        
        x_fp = []
        for a in x:
            x_fp.append(fp(a, signed=1, m=2, n=0, rounding='convergent'))

    def convolve(self):
        tx_signal = np.convolve(self.x, self.hsrrc)
        tx_signal_fp = np.convolve(self.x_fp, self.hsrrc_fp)

    def sqnr(self): 
        quant_err = tx_signal-tx_signal_fp
        mean = statistics.mean([float(fp) for fp in quant_err])
        stdev = statistics.stdev([float(fp) for fp in quant_err])
        #print(mean, stdev)
        #print (f'{hsrrc_fp[0]:q}, {x_fp[0]:q}, {tx_signal_fp[0]:q}')

        p_noise = float(np.sum(quant_err**2)) / len(quant_err)
        p_x = np.sum(x**2) / len(x)
        sqnr = 10*np.log10(p_x/p_noise)
        return sqnr

