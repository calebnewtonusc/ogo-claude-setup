#!/bin/bash
# Dry-run the installer against an empty HOME and check it changes nothing.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
bash -n "$HERE/install.sh"
HOME="$T" bash "$HERE/install.sh" --dry-run >"$T/out.txt" 2>&1 || { cat "$T/out.txt"; exit 1; }
[ -z "$(ls -A "$T" | grep -v out.txt)" ] || { echo "dry run wrote files:"; ls -A "$T"; exit 1; }
for d in "$HERE"/skills/*/; do [ -f "$d/SKILL.md" ] || { echo "missing SKILL.md in $d"; exit 1; }; done
if grep -rIl -i "joelnewton\|zeutara\|amber circles" "$HERE" --exclude-dir=.git --exclude=smoke.sh; then echo "personal text left"; exit 1; fi
echo "smoke ok"
