import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

num_symbols = 1000
sps = 16

bits = np.random.randint(0, 2, num_symbols) # Our data to be transmitted, 1's and 0's

x = np.array([])
for bit in bits:
    pulse = np.zeros(sps)
    pulse[0] = bit*2-1 # set the first value to either a 1 or -1
    x = np.concatenate((x, pulse)) # add the 8 samples to the signal

# Create our raised-cosine filter
num_taps = 43
beta = 0.35
Ts = sps # Assume sample rate is 1 Hz, so sample period is 1, so *symbol* period is 8
t = np.arange(-21, 22) # remember it's not inclusive of final number
h = np.sinc(t/Ts) * np.cos(np.pi*beta*t/Ts) / (1 - (2*beta*t/Ts)**2)
h_int = h * (4096)
h_int = h_int.astype(int)

x = x.astype(int)

x_sum = np.array([])
# Filter our signal, in order to apply the pulse shaping
#x_shaped = np.convolve(x, h_int)

for j in range(num_symbols - num_taps):
    x_part = x[j : j + num_taps]
    x_part = np.flip(x_part)
    value = 0
    for k in range(num_taps):
        value = value + (x_part[k] * h[k])
        x_sum = np.concatenate((x_sum, [value])) 

#hist, bin_edges = np.histogram(x_shaped, bins = 20)
#print( hist, bin_edges)
print( min(x_sum), max(x_sum))
plt.hist(x_sum, bins = 51)
plt.grid(True)
plt.show()
