import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


step = 2**10
t = np.arange(0, step)
sin_lut = np.sin(np.arange (0, 2*np.pi, 2*np.pi/step))
s = []
freq=50
#phase = step//2
for bin in t:
    phi = (freq*bin) % step
    s.append(sin_lut[phi])


#plt.plot(s, '.')
#plt.hist(s, bins = 50)


S = np.fft.fft(s)

plt.stem(np.fft.fftfreq(step), np.abs(S))



plt.grid(True)
plt.show()