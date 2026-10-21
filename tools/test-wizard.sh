#!/usr/bin/env bash
# Plays the whole wizard with Windows line endings (CRLF) in a throwaway copy, and checks the ending.
# Run from the repo root: bash tools/test-wizard.sh
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -R "$repo/start.sh" "$repo/steps" "$repo/data" "$tmp/"; mkdir "$tmp/onedrive"

answer() { sed -n 's/^answer: //p' "$repo/steps/$(printf %02d "$1").txt" | tr -d '\r'; }
{
  echo ""                                   # act 1 intro
  for n in $(seq 1 15); do
    [[ $n == 4 || $n == 8 ]] && echo ""     # act intros
    echo w; echo i; echo ""; echo ""        # read why + inside, back to Do, step done
    [[ $n == 1 ]] && echo "Tester"
    case $n in 7|13) echo 8 ;; 15) echo 9 ;; *) answer "$n" ;; esac
    [[ $n == 15 ]] || echo ""               # Enter for the next step
  done
} | sed 's/$/\r/' > "$tmp/input"

out=$(cd "$tmp" && WORKSHOP_TEST=1 WORKSHOP_ONEDRIVE="$tmp/onedrive" bash start.sh < input 2>&1)
fail=0
check() { if grep -q -- "$1" <<<"$out"; then echo "ok   $2"; else echo "FAIL $2"; fail=1; fi; }
check "Barista Tester, take a bow" "reaches the finale"
check "Partner" "a perfect run reaches Partner"
check "Badges     8 of 8" "a perfect run earns all 8 badges"
check "12 of 12 right the first time" "every quiz answer key matches"
[[ -f "$tmp/onedrive/GT-Agent-Workshop/koffie.xlsx" ]] && echo "ok   step 2 copied the data" || { echo "FAIL step 2 copy"; fail=1; }
long=$(cd "$repo/steps" && python3 -c "
import glob,re
for f in sorted(glob.glob('*.txt')):
    for i,l in enumerate(open(f,encoding='utf-8'),1):
        l=re.sub(r'\*\*','',l.rstrip('\n'))
        if len(l)>70 and not l.startswith('because:'): print(f'{f}:{i}: {len(l)} columns')")
odd=$(cd "$repo/steps" && grep -n '\*\*' *.txt | awk -F'\\*\\*' 'NF % 2 == 0 {print}')
[[ -z "$odd" ]] && echo "ok   bold markers open and close on the same line" || { echo "FAIL bold split over lines:"; echo "$odd"; fail=1; }
[[ -z "$long" ]] && echo "ok   every step line fits 70 columns" || { echo "FAIL lines too long:"; echo "$long"; fail=1; }
[[ -n "${SHOW:-}" ]] && printf "%s\n" "$out" > "$SHOW"
((fail)) && { echo; echo "$out" | tail -40; exit 1; }
echo "all checks passed"
