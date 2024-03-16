import os
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

samples_from_bsv = 81
sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

def gen_signal():
    num_symbols = int(9*8*fsamples)
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
    n = (np.random.randn(len(tx_signal)) + 1j*np.random.randn(len(tx_signal)))/np.sqrt(2) # AWGN with unity power
    tx_signal = tx_signal + n/100

    #delay pre RX
    delay = 0.1 # fractional delay, in samples
    N = 21 # number of taps
    n = np.arange(-N//2, N//2) # ...-3,-2,-1,0,1,2,3...
    h = np.sinc(n - delay) # calc filter taps
    h *= np.hamming(N) # window the filter to make sure it decays to 0 on both sides
    h /= np.sum(h) # normalize to get unity gain, we don't want to change the amplitude/power
    rx_signal = np.convolve(tx_signal, h) # apply filter

    #rx - step 2: freq offset from different LO
    fo = fsamples*0.25 #freq offset in %
    t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
    rx_fo_delay= rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift
    return rx_fo_delay

#########################################################################################

def perform_estimation_n_fix(rx_signal: np.array):
    #rx - step 3: delay 'n' multiply coarse freq error estimation
    freq_error_log = []
    err_log = []
    conj_log = []
    last_rx = complex(0,0)
    err_ = complex(0,0)
    sum = 0
    for rx in rx_signal:
        sum += 1
        conj = (rx * last_rx.conjugate())
        err_ += conj
        conj_log.append(conj)
        err_log.append(err_)
        #print("coarseFreq.addSample(cmplx({:.6f}".format(rx.real), ",", "{:.6f}));".format(rx.imag))
        if sum > 8*sps:
            #print(((sps/2)/(np.pi*Tsymbol)))
            error = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real)
            #print(error)
            freq_error_log.append(error)
            sum = 0
            err_ = complex(0,0)
            rx = complex(0,0)
        last_rx = rx
    #apply freq error fix
    freq_error_mean = np.array(freq_error_log).mean()
    freq_fix = fsamples*freq_error_mean
    t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
    vector_fix = np.exp(-1j*2*np.pi*freq_fix*t)
    coarse_freq_corrected_python = rx_signal * vector_fix # perform freq shift
    return coarse_freq_corrected_python

##################################################################################

def mmted(rx_signal_downsampled: np.array): 
    #time synch: Muller and Mueller
    mu = 0 # initial estimate of phase of sample
    out = np.zeros(len(rx_signal_downsampled) + 10, dtype=complex)
    out_rail = np.zeros(len(rx_signal_downsampled) + 10, dtype=complex) # stores values, each iteration we need the previous 2 values plus current value
    i_in = 0 # input samples index
    i_out = 2 # output index (let first two outputs be 0)
    #samples_interpolated = signal.resample_poly(rx_signal_downsampled, 16, 1)
    #plt.figure(9)
    #plt.plot(samples_interpolated.real, '.-')
    #plt.plot(samples_interpolated.imag, '.-')
    while i_out < len(rx_signal_downsampled) and i_in+16 < len(rx_signal_downsampled):
        #print("int(mu): ", int(mu), " mu: ", mu)
        out[i_out] = rx_signal_downsampled[i_in] # grab what we think is the "best" sample
        #out[i_out] = samples_interpolated[i_in*16 + int(mu*16)]
        out_rail[i_out] = int(np.real(out[i_out]) > 0) + 1j*int(np.imag(out[i_out]) > 0)
        x = (out_rail[i_out] - out_rail[i_out-2]) * np.conj(out[i_out-1])
        y = (out[i_out] - out[i_out-2]) * np.conj(out_rail[i_out-1])
        mm_val = np.real(y - x)
        mu += sps + 0.3*mm_val
        i_in += int(np.floor(mu)) # round down to nearest int since we are using it as an index
        mu = mu - np.floor(mu) # remove the integer part of mu
        i_out += 1 # increment output index
    out = out[2:i_out] # remove the first two, and anything after i_out (that was never filled out)
    return out

###################################################################################

def simulation_step(x_limiter: int, y_limiter: int, mu_limiter: int,
                    rx_signal: np.array, reference_signal: np.array):

    #print values to run bittrue simulation on bsv
    stdout_fd = sys.stdout
    sys.stdout = open("log/mmted-sim-py.log", "w")
    print(f'{x_limiter}.0, {y_limiter}.0, {mu_limiter}.0')
    for datum in rx_signal:
        print("{:.6f}".format(datum.real), 
            ",", 
            "{:.6f}".format(datum.imag))
    sys.stdout.close()
    sys.stdout = stdout_fd

    os.system("./mmTED.exe < log/mmted-sim-py.log > log/mmted-sim-bsv.log")

    #for datum in vector_fix:
    #    print("{:.6f}".format(datum.real), 
    #          ",", 
    #          "{:.6f}".format(datum.imag))

    #print values to run bittrue simulation on bsv
    #stdout_fd = sys.stdout
    #sys.stdout = open("/home/hugo/hueblue-fw/simulations/log/coarseFixed-py.log", "w")
    #for datum in coarse_freq_corrected_python:
    #    print("{:.6f}".format(datum.real), 
    #          ",", 
    #          "{:.6f}".format(datum.imag))
    #sys.stdout.close()
    #sys.stdout = stdout_fd

    #read values from bittrue simulation
    index = 0
    mmted_corrected_bsv = np.zeros(samples_from_bsv, dtype=complex)
    bsv_file = open("log/mmted-sim-bsv.log", "r")
    for line in bsv_file:
        number = line.split(",")
        cmplx = complex(float(number[0]), float(number[1]))
        mmted_corrected_bsv[index] = cmplx
        index += 1
    bsv_file.close()
    #compare to python values

    #for i in range(30, 40):
    #    print("py: ", coarse_freq_corrected_python[i], " bsv: ", coarse_freq_corrected_bsv[i])

    print("x:", x_limiter,  "y:", y_limiter, 
          "mu:", mu_limiter, " sqnr: ", 
          sqnr(reference_signal[0:samples_from_bsv-1], 
               mmted_corrected_bsv[0:samples_from_bsv-1]))
    plt.figure(3)
    plt.plot(reference_signal.real, '.-')
    plt.plot(reference_signal.imag,'.-')
    #plt.figure(4)
    plt.plot(mmted_corrected_bsv.real,'.-') 
    plt.plot(mmted_corrected_bsv.imag, '.-')
    plt.show()

base_signal  =  perform_estimation_n_fix(gen_signal())
fixed_signal =  mmted(base_signal)
#for curr in range(13):
#    for last in range (13):
#        for accum in range(13):
#            for error in range(13):
#                simulation_step(curr, last, accum, error, base_signal, fixed_signal)
simulation_step(0, 0, 0, base_signal, fixed_signal)
#simulation_step(8, 8, 5, 4, base_signal, fixed_signal)