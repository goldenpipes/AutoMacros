"""Builds the release zip: an AutoMacros/ folder with the .toc and the .lua
files it lists, nothing else.

Usage: python -I tools/build_zip.py [--game forever|classicera|tbc|mists|mainline] [--out DIR]

With --game the zip is for that one game: the .toc's Interface line keeps only
that game's number and only that game's Games\\<Game>\\ folder goes in
(releases/AutoMacros-<version>-<game>.zip). Without it, every game
(releases/AutoMacros-<version>.zip). Prints the zip's path."""
import argparse
import os
import re
import sys
import zipfile

# each game: its folder under Games\ and its interface number(s) on the .toc's
# Interface line (see Game.lua for how the addon tells them apart)
GAMES = {
    "forever": ("Forever", lambda n: 16000 <= n < 17000),
    "classicera": ("ClassicEra", lambda n: n < 20000 and not 16000 <= n < 17000),
    "tbc": ("TBC", lambda n: 20000 <= n < 50000),
    "mists": ("Mists", lambda n: 50000 <= n < 100000),
    "mainline": ("Mainline", lambda n: n >= 100000),
}

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ap = argparse.ArgumentParser()
ap.add_argument("--game", choices=sorted(GAMES))
ap.add_argument("--out", default=os.path.join(here, "releases"))
args = ap.parse_args()

toc = open(os.path.join(here, "AutoMacros.toc"), encoding="utf-8").read().splitlines()
version = next((l.split(":", 1)[1].strip() for l in toc if l.startswith("## Version:")), None)
if not version:
    sys.exit("no ## Version: line in AutoMacros.toc")

lines = []
for line in toc:
    if args.game:
        folder, wanted = GAMES[args.game]
        if line.startswith("## Interface:"):
            nums = [n.strip() for n in line.split(":", 1)[1].split(",")]
            keep = [n for n in nums if n.isdigit() and wanted(int(n))]
            if not keep:
                sys.exit(f"the .toc lists no interface number for {args.game}")
            line = "## Interface: " + ", ".join(keep)
        m = re.match(r"Games[\\/]([^\\/]+)[\\/]", line)
        if m and m.group(1) != folder:
            continue   # another game's folder
    lines.append(line)

files = [l.strip() for l in lines if l.strip() and not l.startswith("#")]


def disk(f):
    """the .toc's path (Windows separators) as a path on this machine"""
    return os.path.join(here, *re.split(r"[\\/]", f))


missing = [f for f in files if not os.path.exists(disk(f))]
if missing:
    sys.exit("listed in the .toc but not found: " + ", ".join(missing))

os.makedirs(args.out, exist_ok=True)
name = f"AutoMacros-{version}" + (f"-{args.game}" if args.game else "") + ".zip"
path = os.path.join(args.out, name)
with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("AutoMacros/AutoMacros.toc", "\r\n".join(lines) + "\r\n")
    for f in files:
        z.write(disk(f), "AutoMacros/" + f.replace("\\", "/"))
print(path)
