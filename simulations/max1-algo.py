import os
import sys
sys.path.append('../')
import time
import math
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import commpy.filters as filter
from threading import Thread

print(time.ctime())
ITERATIONS = 100
base_signal = [0] * ITERATIONS
fixed_signal = [0] * ITERATIONS
snr_log = [0] * ITERATIONS

def sqnr(signal: np.array, quantized_signal: np.array) -> float: 
        quant_err = signal - quantized_signal
        p_noise = float(np.sum(np.abs(quant_err) ** 2))
        p_signal = float(np.sum(np.abs(signal) ** 2))
        sqnr = 10*np.log10(p_signal/p_noise)
        return sqnr

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
    ne = float(np.sum(np.abs(n) ** 2)) / len(n)
    se = float(np.sum(np.abs(tx_signal) ** 2)) / len(tx_signal)
    tx_signal = tx_signal + n/(1000*ne/se)

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
    for rx in rx_signal[30:30+4*sps]:
        conj = (rx * last_rx.conjugate())
        err_ += conj
        #print("coarseFreq.addSample(cmplx({:.6f}".format(rx.real), ",", "{:.6f}));".format(rx.imag))
        #print(((sps/2)/(np.pi*Tsymbol)))
        last_rx = rx
    fserror = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real) 
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
        
def simulation_step(sim_exe: str, limiters: list, rx_signal: np.array, reference_signal: np.array,
                    log: list, log_index: int):

    #print values to run bittrue simulation on bsv
    in_file_name = "/tmp/sim-"+str(log_index)+"-py.log"
    out_file_name = "/tmp/sim-"+str(log_index)+"-bsv.log"
    f = open(in_file_name, "w")
    lim_string = ""
    for limiter in limiters:
        lim_string += f',{limiter}.0'
    lim_string = lim_string[1:]
    print(lim_string, file = f)
    for datum in rx_signal:
        print("{:.6f}".format(datum.real), 
            ",", 
            "{:.6f}".format(datum.imag),
            file = f)
    f.close()

    os.system(sim_exe + " < " + in_file_name + " > " + out_file_name)

    #read values from bittrue simulation
    index = 0
    corrected_bsv = np.zeros(500, dtype=complex)
    bsv_file = open(out_file_name, "r")
    for line in bsv_file:
        number = line.split(",")
        cmplx = complex(float(number[0]), float(number[1]))
        corrected_bsv[index] = cmplx
        index += 1
    index = min(len(reference_signal), index)
    bsv_file.close()
    log[log_index] = sqnr(reference_signal[0:index-1], corrected_bsv[0:index-1])


def threaded_simulations(limiters: list, sim_exe: str):
    threads = [None] * ITERATIONS
    for n in range(ITERATIONS):
        threads[n] = Thread(target=simulation_step, 
                args=(sim_exe, limiters, base_signal[n], fixed_signal[n], snr_log, n))
        threads[n].start()
    for n in range(ITERATIONS):
        threads[n].join()

for i in range(ITERATIONS):
    base_signal[i]  =  gen_signal()
    fixed_signal[i] =  perform_estimation_n_fix(base_signal[i])

SQNR_THRESHOLD = 10.0

def max1(n_limiters:int, exe: str):
    limiters = [0] * n_limiters
    threaded_simulations(limiters, exe)
    sqnr = np.array(snr_log)
    print(sqnr.mean(), sqnr.std(), sqnr.min())
    best_result = (sqnr.min())
    while (best_result > SQNR_THRESHOLD):
        print("round", limiters, best_result)
        round_results = []
        tmp_best_result = 0.0
        tmp_result_index = None
        #results of each limiter
        for n in range(n_limiters):
            tmp_limiters = limiters.copy()
            tmp_limiters[n] = tmp_limiters[n] + 1
            threaded_simulations(tmp_limiters, exe)
            sqnr = np.array(snr_log)
            round_results.append(sqnr.min())
            #print(sqnr.mean(), sqnr.std(), sqnr.min())
        #best result on the round
        for n in range(n_limiters):
            if (round_results[n] >= SQNR_THRESHOLD and round_results[n] > tmp_best_result):
                tmp_best_result = round_results[n]
                tmp_result_index = n
        if tmp_result_index == None:
            break
        best_result = tmp_best_result
        limiters[tmp_result_index] = limiters[tmp_result_index] + 1
        if limiters[tmp_result_index] > 16:
            break
    print("final result: ", best_result, "WL:", limiters)

#max1(8, "../CostasLoop/CostasLoop.exe")        
#max1(5, "../mmTED/mmTED.exe")
max1(14, "../coarseFreq/coarseFreq.exe")

print(time.ctime())
