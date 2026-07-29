#!/usr/bin/env python3
# usage: scripts/minify.py [<file>]  (drops comments, unreachable declarations and spacing, stdin by default)
# AI GENERATED; use at your own risk
import re, sys
from pathlib import Path

word_re = re.compile(r"[@$#]{0,2}[A-Za-z_]\w*")
num_re = re.compile(r"0[xXbBoO][0-9a-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?[a-zA-Z_]*")
puncts = ("<<=", ">>=", "...", "??=", "&&&", "|||", "++", "--", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=",
          "==", "!=", "<=", ">=", "&&", "||", "<<", ">>", "::", "..", "=>", "->", "??", "!!")
glued = {p[:2] for p in puncts} | {"//", "/*", "<*", "*>", "*/"}
opaque = ("@operator", "@init", "@finalizer", "@dynamic", "@export", "@extern", "@builtin")

def scan(text):
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif text.startswith("/*", i):
            depth, i = 1, i + 2
            while i < n and depth:
                if text.startswith("/*", i):
                    depth, i = depth + 1, i + 2
                elif text.startswith("*/", i):
                    depth, i = depth - 1, i + 2
                else:
                    i += 1
        elif text.startswith("<*", i):
            j = text.find("*>", i + 2)
            i = n if j < 0 else j + 2
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif c == "`":
            j = text.find("`", i + 1)
            j = n - 1 if j < 0 else j
            out.append(text[i:j + 1])
            i = j + 1
        else:
            m = word_re.match(text, i) or num_re.match(text, i)
            if m:
                out.append(m.group())
                i = m.end()
            else:
                p = next((p for p in puncts if text.startswith(p, i)), c)
                out.append(p)
                i += len(p)
    return out

def chunks(toks):
    out, cur, depth = [], [], 0
    for i, t in enumerate(toks):
        cur.append(t)
        depth += (t in "([{") - (t in ")]}")
        if depth or t not in ";}" or (t == "}" and toks[i + 1:i + 2] == [";"]):
            continue
        out.append(cur)
        cur = []
    if cur:
        out.append(cur)
    return out

def declared(chunk):
    if chunk[0] not in ("fn", "macro") or any(t.startswith(opaque) for t in chunk):
        return None
    head = chunk[1:chunk.index("(")] if "(" in chunk else []
    names = [t for t in head if word_re.fullmatch(t)]
    return names[-1] if names else None

def shake(cs):
    entry = max((i for i, c in enumerate(cs) if c[0] == "module"), default=0)
    names = [declared(c) for c in cs]
    words = [{t for t in c if word_re.fullmatch(t)} for c in cs]
    keep = [n is None or i >= entry for i, n in enumerate(names)]
    while True:
        refs = set().union(*[w for w, k in zip(words, keep) if k])
        grown = [i for i, n in enumerate(names) if not keep[i] and n in refs]
        if not grown:
            return [t for c, k in zip(cs, keep) for t in (c if k else ())]
        for i in grown:
            keep[i] = True

def render(toks, width=200):
    out, line, depth = [], 0, 0
    for t in toks:
        if out:
            last = out[-1][-1]
            if line >= width and not depth and last in ";}":
                out.append("\n")
                line = 0
            elif (last.isalnum() or last in "_@$#") and (t[0].isalnum() or t[0] in "_@$#") or last + t[0] in glued:
                out.append(" ")
                line += 1
        out.append(t)
        line += len(t)
        depth += (t in "([{") - (t in ")]}")
    return "".join(out) + "\n"

def minify(text):
    return render(shake(chunks(scan(text))))

if __name__ == "__main__":
    if len(sys.argv) > 2:
        sys.exit("usage: scripts/minify.py [<file>]")
    sys.stdout.write(minify(Path(sys.argv[1]).read_text() if len(sys.argv) == 2 else sys.stdin.read()))