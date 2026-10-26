"""Rough Lua structure check: strips comments/strings, then checks that block
keywords (function/if/do/repeat vs end/until) and brackets balance, reporting
the first top-level chunk where they do not."""
import re
import sys

src = open(sys.argv[1], encoding="utf-8").read()

# strip long comments, long strings, line comments, quoted strings
out = []
i, n = 0, len(src)
line = 1
while i < n:
    c = src[i]
    if src.startswith("--", i):
        m = re.match(r"--\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            seg = src[i:j + len(close)]
            out.append("\n" * seg.count("\n"))
            i = j + len(close)
            continue
        j = src.find("\n", i)
        i = n if j < 0 else j
        continue
    m = re.match(r"\[(=*)\[", src[i:])
    if m:
        close = "]" + m.group(1) + "]"
        j = src.find(close, i)
        seg = src[i:j + len(close)]
        out.append('""' + "\n" * seg.count("\n"))
        i = j + len(close)
        continue
    if c in "\"'":
        j = i + 1
        while j < n and src[j] != c:
            if src[j] == "\\":
                j += 1
            if src[j] == "\n":
                print(f"unterminated string near line {src.count(chr(10), 0, i) + 1}")
                break
            j += 1
        out.append('""')
        i = j + 1
        continue
    out.append(c)
    i += 1

code = "".join(out)
depth = 0
brackets = []
stack = []  # (keyword, line)
for ln, text in enumerate(code.split("\n"), 1):
    for tok in re.finditer(r"[A-Za-z_][A-Za-z0-9_]*|[(){}\[\]]", text):
        t = tok.group(0)
        if t in ("function", "do", "if", "repeat"):
            stack.append((t, ln))
        elif t in ("end", "until"):
            if not stack:
                print(f"extra '{t}' at line {ln}")
                sys.exit(1)
            stack.pop()
        elif t in "({[":
            brackets.append((t, ln))
        elif t in ")}]":
            if not brackets:
                print(f"extra '{t}' at line {ln}")
                sys.exit(1)
            o, oln = brackets.pop()
            if {"(": ")", "{": "}", "[": "]"}[o] != t:
                print(f"'{o}' from line {oln} closed by '{t}' at line {ln}")
                sys.exit(1)
if stack:
    print("unclosed blocks:", stack[-5:])
if brackets:
    print("unclosed brackets:", brackets[-5:])
if not stack and not brackets:
    print("structure OK")

# WoW's Lua 5.1 refuses a file whose main chunk has more than 200 locals
# (the whole addon then fails to load, slash commands included).
count = 0
for text in code.split("\n"):
    if text.startswith("local function "):
        count += 1
    else:
        m = re.match(r"local\s+([^=]+?)\s*(=|$)", text)
        if m:
            count += len(m.group(1).split(","))
print(f"top-level locals: {count} / 200" + ("  <-- OVER THE LIMIT" if count > 200 else ""))
if stack or brackets or count > 200:
    sys.exit(1)
