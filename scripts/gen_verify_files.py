#!/usr/bin/env python3
# usage: scripts/gen_verify_files.py [<out>]  (default: verify_files.json)
# env: C3FLAGS overrides compile flags (default -O3)
# scans test/**/*.yosupo.c3, emits competitive-verifier config
import json, os, re, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
srcs = sorted(str(p.relative_to(root)) for p in root.glob("src/**/*.c3"))
flags = os.getenv("C3FLAGS", "-O3 --x86cpu=native")
problem = re.compile(r"PROBLEM:?\s*(https?://\S+)", re.I)

files = {}
for t in sorted(root.glob("test/**/*.yosupo.c3")):
    rel = str(t.relative_to(root))
    m = problem.search(t.read_text())
    if not m:
        print(f"skip {rel}: no PROBLEM", file=sys.stderr)
        continue
    url = m.group(1)
    name = t.name.removesuffix(".yosupo.c3")
    bin = f"build/{name}"
    files[rel] = {
        "dependencies": srcs,
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
print(f"{len(files)} tests -> {out}", file=sys.stderr)
