import os
import sys
import time
import math
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import commpy.filters as filter
from threading import Thread

sqnr_log = []
print(time.ctime())
ITERATIONS = 100
base_signal = [0] * ITERATIONS
fixed_signal = [0] * ITERATIONS
snr_log = [0] * ITERATIONS

def sqnr(signal: np.array, quantized_signal: np.array) -> float: 
        quant_err = signal - quantized_signal
        p_noise = float(np.sum(np.abs(quant_err) ** 2)) / len(quant_err)
        p_signal = float(np.sum(np.abs(signal) ** 2)) / len(signal)
        sqnr = 10*np.log10(p_signal/p_noise)
        return sqnr

samples_from_bsv = 108
sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

def gen_signal():
    num_symbols = int(10*8*fsamples)

    in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

    #preamble = np.array([1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0], dtype=int)
    #preamble = np.array([1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0], dtype=int)
    preamble = np.array([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1], dtype=int)
    in_bits = np.concatenate((preamble,in_bits))

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
    last_rx = complex(0,0)
    err_ = complex(0,0)
    sum = 0
    fserror = 0
    for rx in rx_signal[42:]:
        sum += 1
        conj = (rx * last_rx.conjugate())
        err_ += conj
        #print("coarseFreq.addSample(cmplx({:.6f}".format(rx.real), ",", "{:.6f}));".format(rx.imag))
        if sum > 24*sps:
            #print(((sps/2)/(np.pi*Tsymbol)))
            fserror = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real)
        last_rx = rx
    #apply freq error fix
    freq_fix = fsamples*fserror
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
    out = np.array(out[2:i_out]) # remove the first two, and anything after i_out (that was never filled out)
    return out

###################################################################################

def costas_loop(time_synched_signal: np.array):
    
    N = len(time_synched_signal)
    phase = 0
    freq = 0
    # These next two params is what to adjust, to make the feedback loop faster or slower (which impacts stability)
    alpha = 0.132
    beta = 0.00932
    #alpha = 1.0
    #beta = 1.0
    out = np.zeros(N, dtype=complex)
    for i in range(N):
        out[i] = time_synched_signal[i] * np.exp(-1j*phase) # adjust the input sample by the inverse of the estimated phase offset
        error = np.real(out[i]) * np.imag(out[i]) # This is the error formula for 2nd order Costas Loop (e.g. for BPSK)
        #error = phase_detector_4(out[i])
        # Advance the loop (recalc phase and freq offset)
        freq += (beta * error)
        phase += freq + (alpha * error)
        # Optional: Adjust phase so its always between 0 and 2pi, recall that phase wraps around every 2pi
        while phase > np.pi/2:
            phase -= np.pi/2
        while phase < -np.pi/2:
            phase += np.pi/2
    return out

###########################################################################################################
        
def simulation_step(ph_limiter: int, err_limiter: int, fr_limiter: int,
                    rx_signal: np.array, reference_signal: np.array,
                    log: list, log_index: int):

    #print values to run bittrue simulation on bsv
    in_file_name = "log/cl-sim-"+str(log_index)+"-py.log"
    out_file_name = "log/cl-sim-"+str(log_index)+"-bsv.log"
    f = open(in_file_name, "w")
    print(f'{ph_limiter}.0, {err_limiter}.0, {fr_limiter}.0',
          file = f)
    for datum in rx_signal:
        print("{:.6f}".format(datum.real), 
            ",", 
            "{:.6f}".format(datum.imag),
            file = f)
    f.close()

    os.system("./CostasLoop.exe < "+in_file_name+" > "+out_file_name)

    #read values from bittrue simulation
    index = 0
    corrected_bsv = np.zeros(samples_from_bsv+5, dtype=complex)
    bsv_file = open(out_file_name, "r")
    for line in bsv_file:
        number = line.split(",")
        cmplx = complex(float(number[0]), float(number[1]))
        corrected_bsv[index] = cmplx
        index += 1
        if index > samples_from_bsv:
            break
    bsv_file.close()
    #compare to python values

    #for i in range(30, 40):
    #    print("py: ", coarse_freq_corrected_python[i], " bsv: ", coarse_freq_corrected_bsv[i])

    #print("phase:", ph_limiter,  "err:", err_limiter, 
    #      "freq:", fr_limiter, " sqnr: ", 
    #      sqnr(reference_signal[0:samples_from_bsv-1], 
    #           corrected_bsv[0:samples_from_bsv-1]))
    log[log_index] = sqnr(reference_signal[0:index-1], corrected_bsv[0:index-1])
    
    #plt.figure(3)
    #plt.plot(reference_signal.real, '.-')
    #plt.plot(reference_signal.imag,'.-')
    #plt.figure(4)
    #plt.plot(corrected_bsv.real,'.-') 
    #plt.plot(corrected_bsv.imag, '.-')
    #plt.show()

def threaded_simulations(x: int, y:int, mu:int):
    threads = [None] * ITERATIONS
    for n in range(ITERATIONS):
        threads[n] = Thread(target=simulation_step, 
                args=(x, y, mu, base_signal[n], fixed_signal[n], snr_log, n))
        threads[n].start()
    for n in range(ITERATIONS):
        threads[n].join()

for i in range(ITERATIONS):
    base_signal[i]  =  mmted(perform_estimation_n_fix(gen_signal()))
    fixed_signal[i] =  costas_loop(base_signal[i])

def full_simulation():
    for ph in range(6,11):
        for err in range (6,11):
            for freq in range(6,11):
                threaded_simulations(ph, err, freq)
                log = np.array(snr_log)
                print("mean:", "{:.3f}".format(log.mean()), 
                        "std:", "{:.3f}".format(log.std()),
                        "min:", "{:.3f}".format(log.min()),
                        "WL:", ph, err, freq)

#simulation_step(0, 0, 0, base_signal[0], fixed_signal[0], snr_log, 0)
#print("sqnr:", "{:.3f}".format(snr_log[0]))
#simulation_step(6, 6, 4, 6, 6, base_signal[0], fixed_signal[0], snr_log, 0)
#print("sqnr:", "{:.3f}".format(snr_log[0]))

full_simulation()

print(time.ctime())