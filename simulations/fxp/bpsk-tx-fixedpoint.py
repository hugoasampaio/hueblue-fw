import math
import numpy as np
import matplotlib.pyplot as plt
import commpy.filters as filter
from fixedpoint import FixedPoint as fp
import statistics


def step_convolve(signal, filter):
    sum = [0]*(len(signal)+len(filter)-1)
    step_sum = fp(0, signed=1, m=m, n=n, rounding='convergent')
    _signal = list(signal)
    _signal.extend( [fp(0, signed=1, m=m, n=n, rounding='convergent')]*len(filter))
    _filter = list(filter)
    _filter.extend([fp(0, signed=1, m=m, n=n, rounding='convergent')]*len(signal))
    for index_signal in range(0,len(signal)+len(filter)-1):
        for index_filter in range(0,index_signal+1):
            step_sum += _signal[index_signal-index_filter] * _filter[index_filter]
        sum[index_signal]=step_sum
        #print(float(step_sum))
        step_sum = fp(0, signed=1, m=m, n=n, rounding='convergent')
    return sum
        

class qpsk_tx:
    sps = 8
    fsamples = 1 # assume our sample rate is 1 Hz
    Tsample = 1/fsamples # calc sample period
    Tsymbol = Tsample*sps
    x = np.array([])
    hsrrc = None
    hsrrc_fp = []
    x_fp = []
    tx_signal = None
    tx_signal_fp = None
    tx_signal_fp_convolve = None
    def __init__(self, m, n, bins = 50, srrc_taps = 43, beta = 0.50):
        num_symbols = int(bins*self.fsamples)
        in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's
        for bit in in_bits:
            pulse = np.zeros(self.sps)
            pulse[0] = bit*2-1 # set the first value to either a 1 or -1
            self.x = np.concatenate((self.x, pulse)) # add the 8 samples to the signal

        _, self.hsrrc = filter.rrcosfilter(srrc_taps, beta, self.Tsymbol, self.fsamples)

        for a in self.hsrrc:
            self.hsrrc_fp.append(fp(a, signed=1, m=m, n=n, rounding='convergent'))
        
        for a in self.x:
            self.x_fp.append(fp(a, signed=1, m=m, n=n, rounding='convergent'))

    def convolve(self):
        self.tx_signal = np.convolve(self.x, self.hsrrc)
        self.tx_signal_fp = step_convolve(self.x_fp, self.hsrrc_fp)

    def sqnr(self): 
        quant_err = self.tx_signal - self.tx_signal_fp
        #mean = statistics.mean([float(fp) for fp in quant_err])
        #stdev = statistics.stdev([float(fp) for fp in quant_err])
        #print(mean, stdev)
        #print (f'{hsrrc_fp[0]:q}, {x_fp[0]:q}, {tx_signal_fp[0]:q}')
        #print(quant_err)
        #print(type(quant_err[0]))
        p_noise = float(np.sum(quant_err**2)) / len(quant_err)
        p_x = np.sum(self.x**2) / len(self.x)
        sqnr = 10*np.log10(p_x/p_noise)
        #print(p_noise, p_x)
        return sqnr

LIMIT_SQNR = 30.0
step_sqnr = 0.0
sqnr_list = []
fwl_list = []
m = 2
n = 32
sim = qpsk_tx(m,n)
#sim.convolve()
#sim.sqnr()
#plt.figure(1)
#plt.plot(sim.tx_signal, '.-')
#plt.plot(sim.tx_signal_fp, '.')
#plt.figure(2)
#plt.plot(sim.tx_signal_fp, '.-')
#plt.plot(sim.tx_signal_fp_convolve, '.')
#plt.show()
print("SQNR\tFWL começa com 32")
while(1):
    sim.convolve()
    sim_sqnr = sim.sqnr()
    if (sim_sqnr < LIMIT_SQNR):
        print("%.2f" % sim_sqnr)
        break
    step_sqnr = sim_sqnr
    print("%.2f" % step_sqnr)
    sqnr_list.append(sim_sqnr)
    fwl_list.append(n)
    n -= 1
    for i in range(len(sim.hsrrc_fp)):
        sim.hsrrc_fp[i].resize(m, n)
plt.plot(fwl_list, sqnr_list, '.-', )
plt.ylabel("SQNR (dB)")
plt.xlabel("FWL")
plt.show()