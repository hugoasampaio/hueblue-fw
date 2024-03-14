import math
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import commpy.filters as filter

sps = 4 #samples per symbol
fsamples = 1 # assume our sample rate is 1 Hz
Tsample = 1/fsamples # calc sample period
Tsymbol = Tsample*sps

num_symbols = int(10*fsamples)

in_bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

x = np.array([])
for bit in in_bits:
    pulse = np.zeros(sps)
    pulse[0] = bit*2-1 # set the first value to either a 1 or -1
    x = np.concatenate((x, pulse)) # add the 8 samples to the signal

plt.figure(1)
plt.plot(in_bits, '.-')

num_taps = 42
beta = 0.50
_, hsrrc = filter.rcosfilter(num_taps, beta, Tsymbol, fsamples)

tx_signal = np.convolve(x, hsrrc)

#plt.figure(2)
#plt.plot(tx_signal.real,'.-')
#plt.plot(tx_signal.imag,'.-')

print("tx: ", np.sqrt(np.mean(tx_signal.imag**2)), ", ", np.sqrt(np.mean(tx_signal.real**2)))

#AWGN 
n = (np.random.randn(len(tx_signal)) + 1j*np.random.randn(len(tx_signal)))/np.sqrt(2) # AWGN with unity power
tx_signal = tx_signal + n/10

print("awgn: ", np.sqrt(np.mean(tx_signal.imag**2)), ", ", np.sqrt(np.mean(tx_signal.real**2)))

#delay pre RX
delay = 0.1 # fractional delay, in samples
N = 21 # number of taps
n = np.arange(-N//2, N//2) # ...-3,-2,-1,0,1,2,3...
h = np.sinc(n - delay) # calc filter taps
h *= np.hamming(N) # window the filter to make sure it decays to 0 on both sides
h /= np.sum(h) # normalize to get unity gain, we don't want to change the amplitude/power
tx_delayed_signal = np.convolve(tx_signal, h) # apply filter

print("delay: ", np.sqrt(np.mean(tx_delayed_signal.imag**2)), ", ", np.sqrt(np.mean(tx_delayed_signal.real**2)))

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
fo = fsamples*0.28 #freq offset in %
t = np.arange(0, Tsample*len(rx_signal), Tsample) # create time vector
rx_fo_delay= rx_signal * np.exp(1j*2*np.pi*fo*t) # perform freq shift

print("freq shift: ", np.sqrt(np.mean(rx_fo_delay.imag**2)), ", ", np.sqrt(np.mean(rx_fo_delay.real**2)))

#plt.figure(6)
#plt.plot(rx_fo_delay.real, '.-')
#plt.plot(rx_fo_delay.imag, '.-')

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
    #print("coarseFreq.addSample(cmplx({:.8f}".format(rx.real), ",", "{:.8f}));".format(rx.imag))
    if sum > 16*sps:
        #print(err_)
        error = ((sps/2)/(np.pi*Tsymbol)) * math.atan2(err_.imag, err_.real)
        freq_error_log.append(error)
        sum = 0
    last_rx = rx
#apply freq error fix
#print("err_ min:", min(err_log), "\terr_ max:", max(err_log))
#print("conj min:", min(conj_log), "\tconj max:", max(conj_log))
#print("freq error min:", min(freq_error_log), "\tmax:", max(freq_error_log))
freq_error_mean = np.array(freq_error_log).mean()
#print(freq_error_mean)
freq_fix = fsamples*freq_error_mean
t = np.arange(0, Tsample*len(rx_fo_delay), Tsample) # create time vector
vector_fix = np.exp(-1j*2*np.pi*freq_fix*t)
rx_signal_downsampled = rx_fo_delay * vector_fix # perform freq shift

#for r in rx_signal_downsampled:
#    print(" mmTed.addSample(cmplx({:.8f}".format(r.real), ",", "{:.8f}));".format(r.imag))
#plt.figure(7)
#plt.plot( freq_error_log, '.-')
print("after dnm: ", np.sqrt(np.mean(rx_signal_downsampled.imag**2)), ", ", np.sqrt(np.mean(rx_signal_downsampled.real**2)))

#downsample
#rx_signal_downsampled = []
#for index in range(0, len(rx_signal_freq_coarse)):
#    rx_signal_downsampled.append(rx_signal_freq_coarse[index])

#rx_signal_downsampled = np.array(rx_signal_downsampled, dtype=complex)

#plt.figure(9)
#plt.plot( rx_signal_downsampled.real, '.-')
#plt.plot( rx_signal_downsampled.imag, '.-')

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
    print("int(mu): ", int(mu), " mu: ", mu)
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
time_synched_signal = out # only include this line if you want to connect this code snippet with the Costas Loop later on

#for r in time_synched_signal:
#    print(" cc.addSample(cmplx({:.8f}".format(r.real), ",", "{:.8f}));".format(r.imag))
print("after mmted: ", np.sqrt(np.mean(time_synched_signal.imag**2)), ", ", np.sqrt(np.mean(time_synched_signal.real**2)))

#plt.figure(10)
#plt.plot(time_synched_signal.real, '.-')
#plt.plot(time_synched_signal.imag, '.-')

#fine freq sync: costas loop
N = len(time_synched_signal)
phase = 0
freq = 0
# These next two params is what to adjust, to make the feedback loop faster or slower (which impacts stability)
alpha = 0.132
beta = 0.00932
#alpha = 1.0
#beta = 1.0
out = np.zeros(N, dtype=complex)
freq_log = []
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
    freq_log.append(phase * fsamples / (2*np.pi)) # convert from angular velocity to Hz for logging
    #print("phase: ", phase)

print("after cc: ", np.sqrt(np.mean(out.imag**2)), ", ", np.sqrt(np.mean(out.real**2)))

# Plot freq over time to see how long it takes to hit the right offset
#plt.figure(11)
#plt.plot(freq_log,'.-')

plt.figure(12)
plt.plot(out.real, '.-')
plt.plot(out.imag, '.-')

#decode
out_bits = []
for i in out:
    if i.real > 0:
        out_bits.append(1);
    else:
        out_bits.append(0);

#plt.figure(13)
#plt.plot(out_bits, '.-')

#plt.show()