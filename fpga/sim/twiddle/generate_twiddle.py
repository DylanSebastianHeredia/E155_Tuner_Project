# generate twiddle factors for an N-point FFT.
# The real and imaginary parts are q-bit two's complement integers,
# concatenated into a 'twiddle.vectors' file.

import numpy as np

N = 512
q = 16

def int2bin(integer, digits):
    """
    Convert a signed integer into its two's complement representation.
    From https://stackoverflow.com/a/53839867/6115747.

    Parameters
    ----------
    integer : int
        Integer to convert to binary.
    digits  : int
        Size (in binary digits) of the two's complement number.
        Assumes the integer is small enough to fit into this size.

    Returns
    -------
    binary : str
       Binary string containing the two's complement representation.
    """
    if integer >= 0:
        return bin(integer)[2:].zfill(digits)
    else:
        return bin(2**digits + integer)[2:]

i2b = np.vectorize(int2bin)
n = np.arange(N/2)

# generate real parts of the twiddle factors.
w_re = np.cos(2*np.pi*n/N)
w_re = (w_re * (2**(q-1) - 1)).astype('int')
w_re = i2b(w_re, q)

# generate imaginary parts of the twiddle factors.
w_im = -np.sin(2*np.pi*n/N)
w_im = (w_im * (2**(q-1) - 1)).astype('int')
w_im = i2b(w_im, q)

# write the memory a rom file to be read by Quartus
with open("twiddle.vectors", 'w') as f:
    for i in range(len(w_re)):
        f.write(w_re[i] + "" + w_im[i] + "\n")

# write the memory to a rom file to be read by ModelSim (for test).
with open("E155_Tuner_Project/fpga/sim/twiddle/twiddle.vectors", 'w') as f:
    for i in range(len(w_re)):
        f.write(w_re[i] + "" + w_im[i] + "\n")

# write the memory to a test file in hex.
with open("twiddle_hex.txt", 'w') as f:
    for i in range(len(w_re)):
        f.write(f"{int(w_re[i],base=2):04x}{int(w_im[i],base=2):04x}\n")

# write the memory to a test file in hex formatted for LaTeX table.
with open("twiddle_hex_formatted.txt", 'w') as f:
    for i in range(len(w_re)):
        f.write(f"{i} & \\texttt{{({int(w_re[i],base=2):04x})}}+j\\texttt{{({int(w_im[i],base=2):04x})}}\\\\\n")