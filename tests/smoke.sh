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
# A real config run in an empty HOME puts the checks on PATH and the hook in settings,
# and a second run adds nothing.
H="$T/home"; mkdir "$H"
cfg() { HOME="$H" PATH="/usr/bin:/bin:$(dirname "$(command -v python3)")" bash "$HERE/install.sh" --no-prereqs --no-plugins --no-skills --no-mcp >"$1" 2>&1; }
cfg "$T/first.txt" || { cat "$T/first.txt"; echo "config run failed"; exit 1; }
for b in agent-check slop-check code-slop ai-scan agent-hook-init; do [ -x "$H/.local/bin/$b" ] || { cat "$T/first.txt"; echo "$b not on PATH"; exit 1; }; done
[ ! -e "$H/.local/bin/__pycache__" ] || { echo "a cache folder was linked as a command"; exit 1; }
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert any("slop-after-edit" in h["command"] for g in d["hooks"]["PostToolUse"] for h in g["hooks"])' "$H/.claude/settings.json" || { echo "PostToolUse slop hook missing"; exit 1; }
cfg "$T/second.txt" || { cat "$T/second.txt"; echo "second config run failed"; exit 1; }
grep -q "installed: 0 " "$T/second.txt" || { cat "$T/second.txt"; echo "second run installed something"; exit 1; }
[ "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(sum("slop-after-edit" in h["command"] for g in d["hooks"]["PostToolUse"] for h in g["hooks"]))' "$H/.claude/settings.json")" = 1 ] || { echo "slop hook registered twice"; exit 1; }

# The checks catch slop, pass clean text, and the hook reports slop on a Write.
printf 'Our robust platform \xe2\x80\x94 seamless.\n' >"$T/bad.md"
printf 'Ogo fixed the bridge retry on Saturday.\n' >"$T/good.md"
! "$H/.local/bin/slop-check" "$T/bad.md" --max 19 >/dev/null || { echo "slop-check passed slop"; exit 1; }
"$H/.local/bin/slop-check" "$T/good.md" --max 19 >/dev/null || { echo "slop-check failed clean prose"; exit 1; }
OUT="$(printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T" "$T/bad.md" | HOME="$H" python3 "$H/.claude/hooks/ogo-setup/slop-after-edit.py")"
grep -q additionalContext <<<"$OUT" || { echo "hook stayed silent on slop"; exit 1; }
OUT="$(printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T" "$T/good.md" | HOME="$H" python3 "$H/.claude/hooks/ogo-setup/slop-after-edit.py")"
[ -z "$OUT" ] || { echo "hook flagged clean prose: $OUT"; exit 1; }
R="$T/repo"; mkdir "$R"; git -C "$R" init -q; cp "$T/bad.md" "$R/notes.md"; git -C "$R" add notes.md
! (cd "$R" && "$H/.local/bin/agent-check" >/dev/null) || { echo "agent-check passed a slop commit"; exit 1; }
# Docs drift: every plugin and MCP server install.sh adds has a CATALOG.md row, every
# subagent is named in the README, and the README starts people in the Code tab. A
# teammate on a sibling setup repo lost an hour on 2026-10-27 to the chat tab and to
# docs that described an old layout.
for p in $(sed -n '/^PLUGINS=(/,/^)/p' "$HERE/install.sh" | grep -oE '^  [a-z0-9-]+@' | tr -d ' @'); do
  grep -q "^| $p" "$HERE/CATALOG.md" || { echo "plugin $p missing from CATALOG.md"; exit 1; }
done
for m in $(grep -oE 'mcp_add [a-z][a-z-]+' "$HERE/install.sh" | awk '{print $2}' | sort -u); do
  grep -q "^| $m " "$HERE/CATALOG.md" || { echo "mcp $m missing from CATALOG.md"; exit 1; }
done
for a in "$HERE"/claude/agents/*.md; do n="$(basename "$a" .md)"; grep -q "$n" "$HERE/README.md" || { echo "agent $n missing from README"; exit 1; }; done
grep -q 'Code tab' "$HERE/README.md" && grep -qF '`</>`' "$HERE/README.md" || { echo "README lost the Code tab step"; exit 1; }
grep -q 'snags.pdf' "$HERE/README.md" || { echo "README lost the snag report ask"; exit 1; }
! grep -q 'GITHUB_PERSONAL_ACCESS_TOKEN=<' "$HERE/CATALOG.md" "$HERE/README.md" || { echo "docs still make people create a GitHub token by hand"; exit 1; }
echo "docs ok"
echo "smoke ok"
