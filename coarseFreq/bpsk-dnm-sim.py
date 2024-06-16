import os
import sys
import math
import time
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
        p_noise = float(np.sum(np.abs(quant_err) ** 2)) / len(quant_err)
        p_signal = float(np.sum(np.abs(signal) ** 2)) / len(signal)
        sqnr = 10*np.log10(p_signal/p_noise)
        return sqnr

samples_from_bsv = 450
sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

def gen_signal(fs_error: float):
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
    fo = fsamples*fs_error #freq offset in %
    t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
    rx_fo_delay= rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift
    return rx_fo_delay

#########################################################################################

def perform_estimation_n_fix(rx_signal: np.array):
    #rx - step 3: delay 'n' multiply coarse freq error estimation
    last_rx = complex(0,0)
    err_ = complex(0,0)
    #sum = 0
    #fserror = 0
    #for rx in rx_signal[30:30*4+30]:
    #    sum += 1
    #    conj = (rx * last_rx.conjugate())
    #    err_ += conj
        #print("coarseFreq.addSample(cmplx({:.6f}".format(rx.real), ",", "{:.6f}));".format(rx.imag))
    #    if sum > 16*sps:
            #print(((sps/2)/(np.pi*Tsymbol)))
    #        fserror = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real)
    #    last_rx = rx
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

###################################################################################

def simulation_step(limiters: list, rx_signal: np.array, reference_signal: np.array,
                    log: list, log_index: int):

    #print values to run bittrue simulation on bsv
    in_file_name = "/tmp/dnm-sim-"+str(log_index)+"-py.log"
    out_file_name = "/tmp/dnm-sim-"+str(log_index)+"-bsv.log"
    f = open(in_file_name, "w")
    lim_string = ""
    for limiter in limiters:
        lim_string += f',{limiter}.0'
    lim_string = lim_string[1:]
    print(lim_string, file= f)
    for datum in rx_signal:
        print("{:.6f}".format(datum.real), 
            ",", 
            "{:.6f}".format(datum.imag), 
            file= f)
    f.close()

    os.system("./coarseFreq.exe < " + in_file_name + " > " + out_file_name)

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
    coarse_freq_corrected_bsv = np.zeros(samples_from_bsv, dtype=complex)
    bsv_file = open(out_file_name, "r")
    for line in bsv_file:
        number = line.split(",")
        cmplx = complex(float(number[0]), float(number[1]))
        coarse_freq_corrected_bsv[index] = cmplx
        index += 1
    bsv_file.close()
    #compare to python values

    #for i in range(30, 40):
    #    print("py: ", coarse_freq_corrected_python[i], " bsv: ", coarse_freq_corrected_bsv[i])
    snr = sqnr(reference_signal[0:index], 
               coarse_freq_corrected_bsv[0:index])
    log[log_index] = snr

    #if (snr < 7.0):
    #    print("n:", n, "sqnr:", snr)
    #    print("c:",curr_lim,"l:",last_lim, 
    #      "a:",accum_lim,"e:",error_lim, 
    #      "cf:",cplxFix_lim,"x:",xFix_lim,"y:",yFix_lim,
    #      " sqnr:", snr)
    #plt.figure(1)
    #plt.plot(reference_signal.real, '.-')
    #plt.plot(reference_signal.imag,'.-')
    #plt.figure(2)
    #plt.plot(coarse_freq_corrected_bsv.real,'.-') 
    #plt.plot(coarse_freq_corrected_bsv.imag, '.-')
    #plt.show()
    #return snr

def threaded_simulations(limiters:list):
    threads = [None] * ITERATIONS
    for n in range(ITERATIONS):
        threads[n] = Thread(target=simulation_step, 
                args=(limiters, base_signal[n], fixed_signal[n], snr_log, n))
        threads[n].start()
    for n in range(ITERATIONS):
        threads[n].join()

#for curr in range(6,10):
#    for last in range (6,10):
#        for accum in range(3,4):
#            for cx in range(6,10):
#                for x in range(3,4):
#                    for y in range(2,3):
#                        threaded_simulations(curr, last, accum, cx, x, y)
#                        log = np.array(snr_log)
#                        print("mean:", "{:.3f}".format(log.mean()), 
#                               "std:", "{:.3f}".format(log.std()), 
#                                "WL:", curr, last, accum, 0, cx, x, y)

for i in range(ITERATIONS):
    base_signal[i]  =  gen_signal(0.25)
    fixed_signal[i] =  perform_estimation_n_fix(base_signal[i])

#threaded_simulations(6, 6, 3, 9, 3, 2)
limiters = [0] * 14
threaded_simulations(limiters)

log = np.array(snr_log)
print("mean:", "{:.3f}".format(log.mean()), 
              "std:", "{:.3f}".format(log.std()),
              "min",  "{:.3f}".format(log.min()))

#for err in np.linspace(0.01, 0.49, 30):
#    base_signal[0]  =  gen_signal(err)
#    fixed_signal[0] =  perform_estimation_n_fix(base_signal[0])
#    limiters = [0] * 14
#    simulation_step(limiters, base_signal[0], fixed_signal[0], snr_log, 0)
#    print("{:.6f}".format(err), "{:.6f}".format(snr_log[0]))

#base_signal[0]  =  gen_signal(0.085)
#fixed_signal[0] =  perform_estimation_n_fix(base_signal[0])
#simulation_step(0, 0, 0, 0, 0, 0, 0,0,0,0,0, base_signal[0], fixed_signal[0], snr_log, 0)
#print("{:.6f}".format(0.085), "{:.6f}".format(snr_log[0]))

print(time.ctime())
#simulated annealing

#masks = [12, 12, 12, 12, 12, 12]
#tmax = 12*6
#temp0 = tmax
#threaded_simulations(12,12,12,12,12,12)
#candidate_sqnr = np.array(snr_log).mean()
#print("c mean:", "{:.3f}".format(candidate_sqnr), 
#    "std:", "{:.3f}".format(np.array(snr_log).std()), 
#    "WL: 12, 12, 12, 12, 12, 12")
#while temp0 > 0:
#    index = np.random.randint(0, 6)
#    next_masks = masks
#    if masks[index] > 0:
#       next_masks[index] = masks[index] - 1 
#    threaded_simulations(next_masks[0], next_masks[1], next_masks[2], next_masks[3],
#                            next_masks[4], next_masks[5])
#    next_candidate_sqnr = np.array(snr_log).mean()
#    print("nc mean:", "{:.3f}".format(next_candidate_sqnr), 
#    "std:", "{:.3f}".format(np.array(snr_log).std()), 
#    "WL:", next_masks[0], next_masks[1], next_masks[2], next_masks[3],
#                            next_masks[4], next_masks[5])
#    deltaE = candidate_sqnr - next_candidate_sqnr
#    print("exp:", np.exp(-deltaE/temp0), "delta:", deltaE) 
#    if deltaE <= 0:
#        masks = next_masks
#        candidate_sqnr = next_candidate_sqnr
#    elif np.random.rand() < np.exp(-deltaE/temp0):
#        masks = next_masks
#        candidate_sqnr = next_candidate_sqnr
#    temp0 -= 1

