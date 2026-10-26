"""BLP2 with raw BGRA pixels (encoding 3) -> PNG. Optional crop: x y w h, and a
scale factor to enlarge small crops (nearest neighbour) for looking at pixels.
usage: blp_to_png.py in.blp out.png [x y w h [scale]] [--alpha]
--alpha writes the alpha channel as grey (to see a mask's shape)."""
import struct, sys, zlib

args = [a for a in sys.argv[1:] if not a.startswith("--")]
alpha_only = "--alpha" in sys.argv
data = open(args[0], "rb").read()
_, enc, _, _, _, W, H = struct.unpack_from("<IBBBBII", data, 4)
off = struct.unpack_from("<16I", data, 20)[0]
assert data[:4] == b"BLP2" and enc == 3, "only raw BGRA BLP2 handled"
x0, y0, w, h, scale = 0, 0, W, H, 1
if len(args) >= 6:
    x0, y0, w, h = map(int, args[2:6])
if len(args) >= 7:
    scale = int(args[6])

rows = []
for y in range(y0, y0 + h):
    row = bytearray()
    for x in range(x0, x0 + w):
        i = off + (y * W + x) * 4
        b, g, r, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        px = bytes((a, a, a, 255)) if alpha_only else bytes((r, g, b, a))
        row += px * scale
    for _ in range(scale):
        rows.append(b"\x00" + bytes(row))

def chunk(tag, body):
    c = struct.pack(">I", len(body)) + tag + body
    return c + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w * scale, h * scale, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open(args[1], "wb").write(png)
print("wrote", args[1], w * scale, "x", h * scale)
