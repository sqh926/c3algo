#!/usr/bin/env python3
# usage: scripts/minify.py [<file>]  (drops comments and indentation, stdin by default)
# AI GENERATED; use at your own risk
import sys
from pathlib import Path

def uncomment(text):
    out, marks = [], []
    i, n = 0, len(text)

    def emit(s, raw=False):
        out.append(s)
        marks.extend([raw] * s.count("\n"))

    while i < n:
        head = text[i:i + 2]
        if head == "//":
            while i < n and text[i] != "\n":
                i += 1
        elif head == "/*":
            depth, i = 1, i + 2
            while i < n and depth:
                if text[i:i + 2] == "/*":
                    depth, i = depth + 1, i + 2
                elif text[i:i + 2] == "*/":
                    depth, i = depth - 1, i + 2
                else:
                    i += 1
            emit(" ")
        elif head == "<*":
            i += 2
            while i < n and text[i:i + 2] != "*>":
                i += 1
            emit(" ")
            i += 2
        elif text[i] in "\"'":
            quote, j = text[i], i + 1
            while j < n and text[j] != quote:
                j += 2 if text[j] == "\\" else 1
            emit(text[i:j + 1])
            i = j + 1
        elif text[i] == "`":
            j = text.find("`", i + 1)
            j = n - 1 if j < 0 else j
            emit(text[i:j + 1], raw=True)
            i = j + 1
        else:
            emit(text[i])
            i += 1
    return "".join(out), marks

def minify(text):
    body, marks = uncomment(text)
    out = []
    for i, line in enumerate(body.split("\n")):
        if i and marks[i - 1]:
            out.append(line)
        elif line.strip():
            out.append(line.strip())
    return "\n".join(out) + "\n"

if __name__ == "__main__":
    if len(sys.argv) > 2:
        sys.exit("usage: scripts/minify.py [<file>]")
    text = Path(sys.argv[1]).read_text() if len(sys.argv) == 2 else sys.stdin.read()
    sys.stdout.write(minify(text))