"""Rough Lua structure check: strips comments/strings, then checks that block
keywords (function/if/do/repeat vs end/until) and brackets balance, reporting
the first top-level chunk where they do not.

Usage: python -I tools/luacheck.py AutoMacros.toc   (every file the .toc lists)
       python -I tools/luacheck.py SomeFile.lua      (one file)

Since 0.102.0 the addon is several files sharing the addon's table: each must
start with the `setfenv(1, ns)` header (see Core.lua), or its top-level names
would become real globals and the other files would not see them."""
import os
import re
import sys


def strip(src):
    """the code with comments removed and strings emptied, lines kept"""
    out = []
    i, n = 0, len(src)
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
                    print(f"  unterminated string near line {src.count(chr(10), 0, i) + 1}")
                    break
                j += 1
            out.append('""')
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check(path, shared):
    """True when the file is fine. shared: it must have the namespace header."""
    name = os.path.basename(path)
    src = open(path, encoding="utf-8").read()
    code = strip(src)
    ok = True
    brackets, stack = [], []
    for ln, text in enumerate(code.split("\n"), 1):
        for tok in re.finditer(r"[A-Za-z_][A-Za-z0-9_]*|[(){}\[\]]", text):
            t = tok.group(0)
            if t in ("function", "do", "if", "repeat"):
                stack.append((t, ln))
            elif t in ("end", "until"):
                if not stack:
                    print(f"{name}: extra '{t}' at line {ln}")
                    return False
                stack.pop()
            elif t in "({[":
                brackets.append((t, ln))
            elif t in ")}]":
                if not brackets:
                    print(f"{name}: extra '{t}' at line {ln}")
                    return False
                o, oln = brackets.pop()
                if {"(": ")", "{": "}", "[": "]"}[o] != t:
                    print(f"{name}: '{o}' from line {oln} closed by '{t}' at line {ln}")
                    return False
    if stack:
        print(f"{name}: unclosed blocks: {stack[-5:]}")
        ok = False
    if brackets:
        print(f"{name}: unclosed brackets: {brackets[-5:]}")
        ok = False
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
    if count > 200:
        print(f"{name}: {count} top-level locals  <-- OVER THE LIMIT (200)")
        ok = False
    if shared and not re.search(r"^local ADDON, ns = \.\.\.$.*?^setfenv\(1, ns\)$", src, re.M | re.S):
        print(f"{name}: missing the header (local ADDON, ns = ... / setfenv(1, ns))")
        ok = False
    print(f"{name}: {'structure OK' if ok else 'PROBLEMS'}, top-level locals {count} / 200")
    return ok


arg = sys.argv[1]
if arg.lower().endswith(".toc"):
    folder = os.path.dirname(os.path.abspath(arg))
    files = [l.strip() for l in open(arg, encoding="utf-8") if l.strip() and not l.startswith("#")]
    missing = [f for f in files if not os.path.exists(os.path.join(folder, f))]
    for f in missing:
        print(f"{f}: listed in the .toc but not found")
    results = [check(os.path.join(folder, f), True) for f in files if f not in missing]
    good = not missing and all(results)
    print(f"{len(files)} files: " + ("all OK" if good else "PROBLEMS"))
    sys.exit(0 if good else 1)
sys.exit(0 if check(arg, False) else 1)
