#!/usr/bin/env python3
# usage: scripts/bundle.py <file>  (inlines the c3algo modules it imports, prints to stdout)
# AI GENERATED; use at your own risk
import re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
mod_re = re.compile(r"^\s*module\s+([\w:]+)", re.M)
imp_re = re.compile(r"^\s*import\s+([^;]+);", re.M)

def modules(srcs):
    out = {}
    for s in srcs:
        for mod in mod_re.findall(s.read_text()):
            out.setdefault(mod, s)
    return out

def imports(body):
    out = []
    for group in imp_re.findall(body):
        out += [mod.strip() for mod in group.split(",")]
    return out

def bundle(path, mod2path, entry="main"):
    body = path.read_text()
    order, seen = [], {path}

    def walk(text):
        for mod in imports(text):
            s = mod2path.get(mod)
            if s is None or s in seen:
                continue
            seen.add(s)
            walk(s.read_text())
            order.append(s)

    walk(body)
    if not mod_re.search(body):
        body = f"module {entry};\n\n{body}"
    parts = [s.read_text().strip() for s in order] + [body.strip()]
    return "\n\n".join(parts) + "\n"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: scripts/bundle.py <file>")
    sys.stdout.write(bundle(Path(sys.argv[1]).resolve(), modules(sorted(root.glob("src/**/*.c3")))))