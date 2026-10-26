"""Measures a frame piece in a raw BGRA BLP2: its bounding box (alpha > 128)
and, for its top rows, where the opaque run starts and ends (how far the
corner cut reaches in from each side).
usage: blp_edges.py in.blp x y w h"""
import struct, sys

data = open(sys.argv[1], "rb").read()
W = struct.unpack_from("<I", data, 12)[0]
off = struct.unpack_from("<16I", data, 20)[0]
x0, y0, w, h = map(int, sys.argv[2:6])

def a(x, y):
    return data[off + (y * W + x) * 4 + 3]

pts = [(x, y) for y in range(y0, y0 + h) for x in range(x0, x0 + w) if a(x, y) > 128]
bx0, bx1 = min(p[0] for p in pts), max(p[0] for p in pts)
by0, by1 = min(p[1] for p in pts), max(p[1] for p in pts)
print("bbox x %d..%d y %d..%d  size %dx%d" % (bx0, bx1, by0, by1, bx1 - bx0 + 1, by1 - by0 + 1))
for y in range(by0, by0 + 12):
    xs = [x for x in range(bx0, bx1 + 1) if a(x, y) > 128]
    if xs:
        print("row +%2d: opaque x %d..%d  (in %d from left, %d from right)"
              % (y - by0, xs[0], xs[-1], xs[0] - bx0, bx1 - xs[-1]))
