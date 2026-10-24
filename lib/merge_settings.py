#!/usr/bin/env python3
"""Merge this setup's settings into ~/.claude/settings.json without replacing anything.

Rules:
- A top-level key that already exists is left alone (statusLine, includeCoAuthoredBy, ...).
- permissions.deny gets new entries appended; existing entries are untouched.
- A hook is appended only when no existing hook already runs the same command.
- The file is backed up before any write, and nothing is written when nothing changes.

Usage: merge_settings.py <settings.json> <fragment.json> <backup_dir> [--dry-run]
"""
import json
import os
import shutil
import sys


def hook_commands(hooks):
    seen = set()
    for groups in hooks.values():
        for group in groups:
            for h in group.get("hooks", []):
                seen.add(h.get("command", ""))
    return seen


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    settings_path, fragment_path, backup_dir = sys.argv[1:4]
    dry = "--dry-run" in sys.argv
    home = os.path.expanduser("~")

    raw = open(fragment_path).read().replace("$HOME", home)
    fragment = json.loads(raw)

    if os.path.exists(settings_path):
        try:
            settings = json.load(open(settings_path))
        except json.JSONDecodeError as e:
            print(f"  ! {settings_path} is not valid JSON ({e}); left it alone")
            return 1
    else:
        settings = {}

    changes = []

    for key, value in fragment.items():
        if key in ("permissions", "hooks"):
            continue
        if key in settings:
            changes.append(f"kept your {key}")
            continue
        settings[key] = value
        changes.append(f"+ {key}")

    deny_new = fragment.get("permissions", {}).get("deny", [])
    if deny_new:
        perms = settings.setdefault("permissions", {})
        deny = perms.setdefault("deny", [])
        added = [d for d in deny_new if d not in deny]
        deny.extend(added)
        if added:
            changes.append(f"+ {len(added)} deny rules")

    existing = hook_commands(settings.get("hooks", {}))
    for event, groups in fragment.get("hooks", {}).items():
        for group in groups:
            new_hooks = [h for h in group["hooks"] if h["command"] not in existing]
            if not new_hooks:
                continue
            target = settings.setdefault("hooks", {}).setdefault(event, [])
            target.append({**group, "hooks": new_hooks})
            existing.update(h["command"] for h in new_hooks)
            changes.append(f"+ {event} hook ({group.get('matcher') or 'all'})")

    real = [c for c in changes if c.startswith("+")]
    for c in changes:
        print(f"  {c}")
    if not real:
        print("  settings.json already has everything, no write")
        return 0
    if dry:
        print("  (dry run, settings.json not written)")
        return 0

    if os.path.exists(settings_path):
        os.makedirs(backup_dir, exist_ok=True)
        shutil.copy2(settings_path, os.path.join(backup_dir, "settings.json"))
    tmp = settings_path + ".ogo-setup.tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, settings_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
