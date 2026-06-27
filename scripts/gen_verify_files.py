#!/usr/bin/env python3
# usage: scripts/gen_verify_files.py [<out>]  (default: verify_files.json)
# env: C3FLAGS overrides compile flags (default -O3)
import json, os, re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
srcs = sorted(str(p.relative_to(root)) for p in root.glob("src/**/*.c3"))
flags = os.getenv("C3FLAGS", "-O3")
mod_re = re.compile(r"^\s*module\s+([\w:]+)", re.M)
imp_re = re.compile(r"^\s*import\s+([^;]+);", re.M)
problem_re = re.compile(r"PROBLEM:?\s*(https?://\S+)", re.I)

text = {s: (root / s).read_text() for s in srcs}
mod2src = {}
for s in srcs:
    for mod in mod_re.findall(text[s]):
        mod2src.setdefault(mod, s)

def deps(body, self=None):
    out = set()
    for group in imp_re.findall(body):
        for mod in group.split(","):
            s = mod2src.get(mod.strip())
            if s and s != self:
                out.add(s)
    return sorted(out)

files = {}
for s in srcs:
    title = next(iter(mod_re.findall(text[s])), s)
    files[s] = {
        "dependencies": deps(text[s], s),
        "document_attributes": {"TITLE": title},
    }

for t in sorted(root.glob("test/**/*.yosupo.c3")):
    rel = str(t.relative_to(root))
    body = t.read_text()
    m = problem_re.search(body)
    if not m:
        print(f"skip {rel}: no PROBLEM", file=sys.stderr)
        continue
    url = m.group(1)
    name = t.name.removesuffix(".yosupo.c3")
    bin = f"build/{name}"
    files[rel] = {
        "dependencies": deps(body),
        "verification": [{
            "type": "problem",
            "problem": url,
            "compile": f"mkdir -p build && c3c compile {rel} {' '.join(srcs)} {flags} -o {bin}",
            "command": f"./{bin}",
        }],
        "document_attributes": {"PROBLEM": url, "TITLE": name},
    }

out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("verify_files.json")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"files": files}, indent=2) + "\n")
print(f"{len(srcs)} library + {len(files) - len(srcs)} verification -> {out}", file=sys.stderr)
