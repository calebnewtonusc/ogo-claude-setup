#!/bin/bash
# PreToolUse: warn before writing a .env file.

set -uo pipefail

f="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$f" ] || exit 0

case "$(basename "$f")" in
  .env | .env.* | *.env)
    # .env.example is meant to be committed and holds placeholders only.
    case "$(basename "$f")" in
      .env.example | .env.sample | .env.template) exit 0 ;;
    esac
    python3 -I <<'PY'
import json
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": (
            "About to write a .env file. Confirm no real secret is going in, "
            "and that .gitignore covers this path before anything is staged."
        ),
    }
}))
PY
    ;;
esac

exit 0
