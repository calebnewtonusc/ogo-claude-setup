#!/bin/bash
# Status line: model | folder + git branch | context used | session cost.
# Reads the session JSON Claude Code sends on stdin and prints one line.
input=$(cat)
py() { python3 -I -c "import json,sys;d=json.load(sys.stdin);print($1)" <<< "$input" 2>/dev/null; }

MODEL=$(py "d.get('model',{}).get('display_name','?')")
CWD=$(py "d.get('workspace',{}).get('current_dir','')")
DIR=$(basename "${CWD:-$PWD}")
PCT=$(py "round(d.get('context',{}).get('used_pct') or 0)")
COST=$(py "d.get('cost',{}).get('total_cost_usd') or 0")

# Branch name only. `git status` can run a repo's own filters and fsmonitor,
# so a cloned repo you haven't vetted could execute code on every redraw.
BRANCH=$(git --no-optional-locks -c core.fsmonitor=false -C "${CWD:-$PWD}" symbolic-ref --short -q HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
  GIT=" \033[38;5;108m⎇ $BRANCH\033[0m"
else
  GIT=""
fi

# context turns amber past 60%, red past 80%
if   [ "${PCT:-0}" -ge 80 ]; then CTX="\033[38;5;203m${PCT}%\033[0m"
elif [ "${PCT:-0}" -ge 60 ]; then CTX="\033[38;5;179m${PCT}%\033[0m"
else CTX="\033[38;5;245m${PCT}%\033[0m"; fi

printf "\033[38;5;110m%s\033[0m \033[38;5;245m│\033[0m \033[1m%s\033[0m%b \033[38;5;245m│\033[0m %b \033[38;5;245m│\033[0m \033[38;5;245m\$%.2f\033[0m" \
  "$MODEL" "$DIR" "$GIT" "$CTX" "$COST"
