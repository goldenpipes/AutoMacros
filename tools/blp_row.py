"""Prints one row (or column) of a raw BGRA BLP2 as alpha and brightness, to see
how thick a frame's ring is.
usage: blp_row.py in.blp x y count [--col]"""
import struct, sys

data = open(sys.argv[1], "rb").read()
W = struct.unpack_from("<I", data, 12)[0]
off = struct.unpack_from("<16I", data, 20)[0]
x0, y0, n = map(int, sys.argv[2:5])
col = "--col" in sys.argv
for i in range(n):
    x, y = (x0, y0 + i) if col else (x0 + i, y0)
    j = off + (y * W + x) * 4
    b, g, r, a = data[j:j + 4]
    print("%s %3d: alpha %3d  rgb %3d %3d %3d" % ("y" if col else "x", y if col else x, a, r, g, b))
