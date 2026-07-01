#!/usr/bin/env bash
# usage: scripts/run.sh [<file>] (no arg = run all tests)
# env: VERBOSE=1 dumps full oj/c3c output on each test
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
oj="${OJ:-$HOME/.local/bin/oj}"
opt="${OPT:--O3}"

srcs=()
while IFS= read -r f; do srcs+=("$f"); done < <(find "$root/src" -name '*.c3' 2>/dev/null)

verbose="${VERBOSE:-0}"

one() {
    local t="$1"
    local label; label=$(basename "$t")
    [ -f "$t" ] || { printf '%-40s %s\n' "$label" "x  no such file" >&2; return 2; }

    local url
    url=$(grep -oiE 'PROBLEM:?[[:space:]]*https?://\S+' "$t" | grep -oiE 'https?://\S+' | head -1)
    [ -n "$url" ] || { printf '%-40s %s\n' "$label" "x  missing // PROBLEM: <url>" >&2; return 2; }

    local slug cases out
    slug=$(basename "${url%%\?*}")
    cases="$root/.cache/$slug"
    if [ -z "$(ls -A "$cases/test" 2>/dev/null)" ]; then
        if ! out=$("$oj" download --system "$url" -d "$cases/test" 2>&1); then
            [ "$verbose" = 1 ] && printf '%s\n' "$out" >&2
            printf '%-40s %s\n' "$label" "x  fetch failed"; return 1
        fi
    fi

    local name bin
    name=$(basename "$t" .c3); name=${name%.yosupo}
    bin="$root/build/$name"
    mkdir -p "$root/build"

    if ! out=$(c3c compile "$t" "${srcs[@]}" "$opt" -o "$bin" 2>&1); then
        [ "$verbose" = 1 ] && printf '%s\n' "$out" >&2
        printf '%-40s %s\n' "$label" "x  build failed"; return 1
    fi

    local rc slowest mark
    local -a judge=()
    local lcp="$HOME/.cache/online-judge-tools/library-checker-problems"
    local probdir; probdir=$(find "$lcp" -maxdepth 2 -type d -name "$slug" 2>/dev/null | head -1)
    if [ -n "$probdir" ] && [ -f "$probdir/checker.cpp" ]; then
        local chk="$root/build/checker_$slug"
        if [ ! -x "$chk" ] || [ "$probdir/checker.cpp" -nt "$chk" ]; then
            g++ -O2 -I "$lcp/common" -I "$probdir" -o "$chk" "$probdir/checker.cpp" 2>/dev/null || true
        fi
        [ -x "$chk" ] && judge=(--judge-command "$chk")
    fi

    out=$("$oj" test -c "$bin" -d "$cases/test" ${judge[@]+"${judge[@]}"} 2>&1); rc=$?
    [ "$verbose" = 1 ] && printf '%s\n' "$out" >&2

    slowest=$(printf '%s\n' "$out" | grep -oiE 'slowest:[[:space:]]*[0-9.]+' | grep -oE '[0-9.]+' | tail -1)
    [ -n "$slowest" ] || slowest="?"

    [ $rc -eq 0 ] && mark="ok" || mark="x "
    printf '%-40s %s  %ss\n' "$label" "$mark" "$slowest"
    return $rc
}

[ $# -gt 0 ] && { one "$1"; exit; }

pass=0 fail=0
while IFS= read -r t; do
    if one "$t"; then ((pass++)); else ((fail++)); fi
done < <(find "$root/test" -name '*.yosupo.c3' | sort)

echo "----------------------------------------------------------------"
echo "fail $fail / pass $pass"
[ $fail -eq 0 ]
