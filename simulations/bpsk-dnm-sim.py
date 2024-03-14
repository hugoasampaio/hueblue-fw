import sys
import math
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import commpy.filters as filter

def sqnr(signal: np.array, quantized_signal: np.array) -> float: 
        quant_err = signal - quantized_signal
        p_noise = float(np.sum(np.abs(quant_err) ** 2)) / len(quant_err)
        p_signal = float(np.sum(np.abs(signal) ** 2)) / len(signal)
        sqnr = 10*np.log10(p_signal/p_noise)
        return sqnr

sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

num_symbols = int(100*fsamples)
in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

x = np.array([])
for bit in in_bits:
    pulse = np.zeros(sps)
    pulse[0] = bit*2-1 # set the first value to either a 1 or -1
    x = np.concatenate((x, pulse)) # add the 8 samples to the signal

num_taps = 42
beta = 0.50
_, hsrrc = filter.rcosfilter(num_taps, beta, Tsymbol, fsamples)

tx_signal = np.convolve(x, hsrrc)

#AWGN 
#n = (np.random.randn(len(tx_signal)) + 1j*np.random.randn(len(tx_signal)))/np.sqrt(2) # AWGN with unity power
#tx_signal = tx_signal + n/10

#delay pre RX
delay = 0.1 # fractional delay, in samples
N = 21 # number of taps
n = np.arange(-N//2, N//2) # ...-3,-2,-1,0,1,2,3...
h = np.sinc(n - delay) # calc filter taps
h *= np.hamming(N) # window the filter to make sure it decays to 0 on both sides
h /= np.sum(h) # normalize to get unity gain, we don't want to change the amplitude/power
tx_delayed_signal = np.convolve(tx_signal, h) # apply filter

#rx - step 1: matched filter
rx_signal = tx_delayed_signal

#rx - step 2: freq offset from different LO
fo = fsamples*0.28 #freq offset in %
t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
rx_fo_delay= rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift

#print values to run bittrue simulation on bsv
stdout_fd = sys.stdout
sys.stdout = open("/home/hugo/hueblue-fw/simulations/log/dnm-sim-py.log", "w")
for datum in rx_fo_delay:
    print("{:.6f}".format(datum.real), 
          ",", 
          "{:.6f}".format(datum.imag))
sys.stdout.close()
sys.stdout = stdout_fd

#rx - step 3: delay 'n' multiply coarse freq error estimation
freq_error_log = []
err_log = []
conj_log = []
last_rx = complex(0,0)
err_ = complex(0,0)
sum = 0
for rx in rx_fo_delay:
    sum += 1
    if sum == 0:
        conj = (rx * rx.conjugate())
        err_ += conj
        err_log.append(err_)
        conj_log.append(conj)
    else:
        conj = (rx * last_rx.conjugate())
        err_ += conj
        conj_log.append(conj)
        err_log.append(err_)
    #print("coarseFreq.addSample(cmplx({:.6f}".format(rx.real), ",", "{:.6f}));".format(rx.imag))
    if sum > 16*sps:
        #print(((sps/2)/(np.pi*Tsymbol)))
        error = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real)
        #error = 4/np.pi * math.atan2(err_.imag, err_.real)
        freq_error_log.append(error)
        sum = 0
    last_rx = rx
#apply freq error fix
freq_error_mean = np.array(freq_error_log).mean()
freq_fix = fsamples*freq_error_mean
t = np.arange(0, Tsample*len(rx_fo_delay), Tsample) # create time vector
vector_fix = np.exp(-1j*2*np.pi*freq_fix*t)
coarse_freq_corrected_python = rx_fo_delay * vector_fix # perform freq shift
for datum in vector_fix:
    print("{:.6f}".format(datum.real), 
          ",", 
          "{:.6f}".format(datum.imag))

#print values to run bittrue simulation on bsv
stdout_fd = sys.stdout
sys.stdout = open("/home/hugo/hueblue-fw/simulations/log/coarseFixed-py.log", "w")
for datum in coarse_freq_corrected_python:
    print("{:.6f}".format(datum.real), 
          ",", 
          "{:.6f}".format(datum.imag))
sys.stdout.close()
sys.stdout = stdout_fd

#read values from bittrue simulation~
index = 0
coarse_freq_corrected_bsv = np.zeros(449, dtype=complex)
bsv_file = open("/home/hugo/hueblue-fw/simulations/log/dnm-sim-bsv.log", "r")
for line in bsv_file:
    number = line.split(",")
    cmplx = complex(float(number[0]), float(number[1]))
    coarse_freq_corrected_bsv[index] = cmplx
    index += 1
bsv_file.close()
#compare to python values

#for i in range(30, 40):
#    print("py: ", coarse_freq_corrected_python[i], " bsv: ", coarse_freq_corrected_bsv[i])

#print(sqnr(coarse_freq_corrected_python[0:449], coarse_freq_corrected_bsv))
#plt.figure(1)
#plt.plot( coarse_freq_corrected_python.real, '.-')
#plt.plot(coarse_freq_corrected_python.imag,'.-')

plt.figure(2)
plt.plot(coarse_freq_corrected_bsv.real,'.-') 
plt.plot(coarse_freq_corrected_bsv.imag, '.-')
plt.show()