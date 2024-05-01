import math
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import commpy.filters as filter

sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

fserror1_log = []
fserror_mean_log = []

num_symbols = int(10*8*fsamples)
for n in range(100):
    in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

    #preamble = np.array([1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0], dtype=int)
    #preamble = np.array([1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0], dtype=int)
    #preamble = np.array([1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0], dtype=int)
    #preamble = np.array([1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0], dtype=int)
    preamble = np.array([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1], dtype=int)
    in_bits = np.concatenate((preamble,in_bits))

    x = np.array([])
    for bit in in_bits:
        pulse = np.zeros(sps)
        pulse[0] = bit*2-1 # set the first value to either a 1 or -1
        x = np.concatenate((x, pulse)) # add the 8 samples to the signal

    #plt.figure(1)
    #plt.plot(in_bits, '.-')

    num_taps = 42
    beta = 0.50
    _, hsrrc = filter.rcosfilter(num_taps, beta, Tsymbol, fsamples)

    tx_signal = np.convolve(x, hsrrc)

    #fig, ax = plt.subplots()

    #ax.plot(tx_signal.real,'.-')
    #ax.plot(tx_signal.imag,'.-')
    #ax.set(xlabel='sample', ylabel='amplitude', title='Baseband Transmitted data')

    #print("tx: ", np.sqrt(np.mean(tx_signal.imag**2)), ", ", np.sqrt(np.mean(tx_signal.real**2)))

    #AWGN 
    n = (np.random.randn(len(tx_signal)) + 1j*np.random.randn(len(tx_signal)))/np.sqrt(2) # AWGN with unity power
    ne = float(np.sum(np.abs(n) ** 2)) / len(n)
    se = float(np.sum(np.abs(tx_signal) ** 2)) / len(tx_signal)
    tx_signal = tx_signal + n/(100*ne/se)

    #print("awgn: ", np.sqrt(np.mean(tx_signal.imag**2)), ", ", np.sqrt(np.mean(tx_signal.real**2)))

    #delay pre RX
    delay = 0.1 # fractional delay, in samples
    N = 21 # number of taps
    n = np.arange(-N//2, N//2) # ...-3,-2,-1,0,1,2,3...
    h = np.sinc(n - delay) # calc filter taps
    h *= np.hamming(N) # window the filter to make sure it decays to 0 on both sides
    h /= np.sum(h) # normalize to get unity gain, we don't want to change the amplitude/power
    tx_delayed_signal = np.convolve(tx_signal, h) # apply filter

    #print("delay: ", np.sqrt(np.mean(tx_delayed_signal.imag**2)), ", ", np.sqrt(np.mean(tx_delayed_signal.real**2)))

    #plt.figure(3)
    #plt.plot(np.real(n/100),np.imag(n/100),'.')
    #plt.grid(True, which='both')
    #plt.axis([-2, 2, -2, 2])

    #plt.figure(4)
    #plt.plot( tx_delayed_signal.real, '.-')
    #plt.plot( tx_delayed_signal.imag, '.-')


    #rx - step 1: matched filter
    #rx_signal = np.convolve(tx_delayed_signal, hsrrc)
    rx_signal = tx_delayed_signal
    #plt.figure(5)
    #plt.plot(rx_signal.real, '.-')
    #plt.plot(rx_signal.imag, '.-')

    #rx - step 2: freq offset from different LO
    fo = fsamples*0.25 #freq offset in %
    t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
    rx_fo_delay= rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift

    #print("freq shift: ", np.sqrt(np.mean(rx_fo_delay.imag**2)), ", ", np.sqrt(np.mean(rx_fo_delay.real**2)))

    #plt.figure(6)
    #fig, ax = plt.subplots()
    #ax.plot(rx_fo_delay.real, '.-')
    #ax.plot(rx_fo_delay.imag, '.-')
    #ax.set(xlabel='sample', ylabel='amplitude', title='Channel Impairments')

    #rx - step 3: delay 'n' multiply coarse freq error estimation
    err_log = []
    conj_log = []
    last_rx = complex(0,0)
    err_ = complex(0,0)
    sum = 0
    fserror = []
    for rx in rx_fo_delay[30:]:
        conj = (rx * last_rx.conjugate())
        err_ += conj
        conj_log.append(conj)
        err_log.append(err_)
        sum += 1
        #print("coarseFreq.addSample(cmplx({:.8f}".format(rx.real), ",", "{:.8f}));".format(rx.imag))
        if sum > 16*sps:
            fserror.append(((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real))
            sum = 0
        last_rx = rx
    #print(fserror[0])
    fserror_mean = np.array(fserror).mean()
    fserror1_log.append(fserror[0])
    fserror_mean_log.append(fserror_mean)

    #apply fix
    freq_fix = fsamples*fserror_mean
    t = np.arange(0, Tsample*len(rx_fo_delay), Tsample) # create time vector
    vector_fix = np.exp(-1j*2*np.pi*freq_fix*t)
    rx_signal_downsampled = rx_fo_delay * vector_fix # perform freq shift

    fig, ax = plt.subplots()
    ax.plot( rx_signal_downsampled.real, '.-', label="real samples")
    ax.plot( rx_signal_downsampled.imag, '.-', label="imaginary samples")
    ax.legend()
    ax.set(xlabel='sample', ylabel='amplitude', title='Delay and Multiply result')
    plt.show()


fserror1_log = np.array(fserror1_log)
fserror_mean_log = np.array(fserror_mean_log)
print("mag:",  np.abs(0.25 - fserror1_log.mean()),
      "%:", 100*(fserror1_log.std()/fserror1_log.mean()))
#print("m- mean:", fserror_mean_log.mean(), "min:", fserror_mean_log.min(), "max:", fserror_mean_log.max())
#print(fserror_mean)
#"1- mean:", fserror1_log.mean(),"std-dev:",fserror1_log.std(),

