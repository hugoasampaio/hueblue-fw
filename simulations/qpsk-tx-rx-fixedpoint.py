import math
import numpy as np
import matplotlib.pyplot as plt
import commpy.filters as filter
from complex_fxp import Complex_fxp as cfxp
import statistics


def step_convolve(signal: list, filter: list) -> list:
    sum = [0]*(len(signal)+len(filter)-1)
    step_sum = cfxp()
    _signal = list(signal)
    _signal.extend([cfxp(0)]*len(filter))
    _filter = list(filter)
    _filter.extend([cfxp(0)]*len(signal))
    for index_signal in range(0,len(signal)+len(filter)-1):
        for index_filter in range(0,index_signal+1):
            step_sum += _signal[index_signal-index_filter] * _filter[index_filter]
        sum[index_signal]=step_sum
        #print(float(step_sum))
        step_sum = cfxp()
    return sum

def sqnr(signal: list, quantized_signal: list) -> float: 
        quant_err = np.array(signal) - np.array(quantized_signal)
        #mean = statistics.mean([float(fp) for fp in quant_err])
        #stdev = statistics.stdev([float(fp) for fp in quant_err])
        #print(mean, stdev)
        #print (f'{hsrrc_fp[0]:q}, {x_fp[0]:q}, {tx_signal_fp[0]:q}')
        #print(quant_err)
        #print(type(quant_err[0]))
        p_noise = float(np.sum(np.abs(quant_err) ** 2)) / len(quant_err)
        p_signal = float(np.sum(np.abs(signal) ** 2)) / len(signal)
        sqnr = 10*np.log10(p_signal/p_noise)
        #print(p_noise, p_x)
        return sqnr
        
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
    rx_fo_delay = None
    rx_fo_delay_fp = None

    def __init__(self, m, n, bins = 50, srrc_taps = 43, beta = 0.50):
        num_symbols = int(bins*self.fsamples)
        in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's
        for bit in in_bits:
            pulse = np.zeros(self.sps)
            pulse[0] = bit*2-1 # set the first value to either a 1 or -1
            self.x = np.concatenate((self.x, pulse)) # add the 8 samples to the signal

        _, self.hsrrc = filter.rrcosfilter(srrc_taps, beta, self.Tsymbol, self.fsamples)

        for a in self.hsrrc:
            self.hsrrc_fp.append(cfxp(a))
        
        for a in self.x:
            self.x_fp.append(cfxp(a))

    def convolve(self):
        self.tx_signal = np.convolve(self.x, self.hsrrc)
        self.tx_signal_fp = step_convolve(self.x_fp, self.hsrrc_fp)

    def delay_signals(self):
        #delay pre RX
        delay = 0.1 # fractional delay, in samples
        N = 21 # number of taps
        n = np.arange(-N//2, N//2) # ...-3,-2,-1,0,1,2,3...
        h = np.sinc(n - delay) # calc filter taps
        h *= np.hamming(N) # window the filter to make sure it decays to 0 on both sides
        h /= np.sum(h) # normalize to get unity gain, we don't want to change the amplitude/power
        self.tx_signal = np.convolve(self.tx_signal, h) # apply filter
        self.tx_signal_fp = np.convolve(self.tx_signal_fp, h) # apply filter
    
    def recv_signals(self):
        #rx - step 1: matched filter
        rx_signal = np.convolve(self.tx_signal, self.hsrrc)
        rx_signal_fp = step_convolve(self.tx_signal_fp, self.hsrrc_fp)

        #rx - step 2: freq offset from different LO
        fo = self.fsamples*0.28 #freq offset in %
        t = np.arange(0, self.Tsample*len(rx_signal), self.Tsample) # create time vector
        self.rx_fo_delay = rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift
        self.rx_fo_delay_fp = rx_signal_fp * np.exp(1j*2*np.pi*fo*t)

    def feq(self, signal: list) -> list:
        freq_error_log = []
        last_rx = complex(0,0)
        err_ = complex(0,0)
        sum = 0
        for rx in signal:
            complex(rx)
            sum += 1
            if sum == 0:
                err_ += (rx * rx.conjugate())
            else:
                err_ += (rx * last_rx.conjugate())
            if sum > 16*self.sps:
                error = ((self.sps/2)/(np.pi*self.Tsymbol)) * math.atan2(err_.imag, err_.real)
                freq_error_log.append(error)
                sum = 0
            last_rx = rx
        return freq_error_log


LIMIT_SQNR = 50.0
step_sqnr = 0.0
m = 2
n = 32
sim = qpsk_tx(m,n)

while(1):
    sim.convolve()
    sim.delay_signals()
    sim.recv_signals()
    rx_freq_error = sim.feq(sim.rx_fo_delay)
    rx_freq_error_fp = sim.feq(sim.rx_fo_delay_fp)

    sqnr_feq = sqnr(rx_freq_error, rx_freq_error_fp)
    if sqnr_feq < LIMIT_SQNR:
        break
    step_sqnr = sqnr_feq
    n -= 1
    for i in range(len(sim.hsrrc_fp)):
        sim.hsrrc_fp[i].resize(m, n)
    for i in range(len(sim.rx_fo_delay_fp)):
        sim.rx_fo_delay_fp[i].resize(m,n)
    
print(step_sqnr, m, n+1)


#sim.convolve()
#print(sqnr(sim.tx_signal, [complex(a) for a in sim.tx_signal_fp]))
#plt.figure(1)
#plt.plot(sim.tx_signal, '.-')
#plt.plot(sim.tx_signal_fp, '.')
#plt.figure(2)
#plt.plot(sim.tx_signal_fp, '.-')
#plt.plot(sim.tx_signal_fp_convolve, '.')
#plt.show()