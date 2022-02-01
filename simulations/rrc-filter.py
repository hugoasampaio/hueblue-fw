import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

num_symbols = 10
sps = 8

bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

x = np.array([])
for bit in bits:
    pulse = np.zeros(sps)
    pulse[0] = bit*2-1 # set the first value to either a 1 or -1
    x = np.concatenate((x, pulse)) # add the 8 samples to the signal
#x = np.zeros(sps*num_symbols)
#x[0] = 1

# Create our raised-cosine filter
num_taps = 41
beta = 0.35
Ts = sps # Assume sample rate is 1 Hz, so sample period is 1, so *symbol* period is 8
t = np.arange(-21, 22) # remember it's not inclusive of final number
h = np.sinc(t/Ts) * np.cos(np.pi*beta*t/Ts) / (1 - (2*beta*t/Ts)**2)
h_integer = h*4095
h_integer = h_integer.astype(int)
h_error = (h*4096) - h_integer
print(h_integer)
print(h_error)
print(np.mean(h_error), np.std(h_error), np.average(h_error))
#plt.figure(1)
#plt.plot(t, h, '.')
#plt.grid(True)
#plt.show()

# Filter our signal, in order to apply the pulse shaping
x_shaped = np.convolve(x, h)
plt.figure(2)
plt.plot(x_shaped, '.-')
for i in range(num_symbols):
    plt.plot([i*sps+num_taps//2+1,i*sps+num_taps//2+1], [min(x_shaped), max(x_shaped)])
plt.grid(True)
plt.show()

