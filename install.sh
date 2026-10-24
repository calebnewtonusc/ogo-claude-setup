#!/bin/bash
# Installs the shared Claude Code setup on a Mac, merged into an existing ~/.claude.
#
#   ./install.sh              install everything this script knows about
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --help       flags
#
# Safe to run more than once. It never overwrites a file you already have:
# a skill, rule, agent, command or MCP server whose name already exists is
# skipped and listed at the end. settings.json and CLAUDE.md are merged
# (keys and lines added, never replaced) after a backup.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETUP_DIR="$CLAUDE_DIR/ogo-setup"
VENDOR="$SETUP_DIR/vendor"
BACKUP_DIR="$CLAUDE_DIR/backups/ogo-setup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0; DO_PREREQS=1; DO_PLUGINS=1; DO_SKILLS=1; DO_MCP=1; DO_CONFIG=1; WITH_RUNPOD=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [flags]

  --dry-run        Print every action, change nothing.
  --no-prereqs     Skip Homebrew packages (git, node, uv, gh, jq, peekaboo...).
  --no-plugins     Skip plugin marketplaces and plugins.
  --no-skills      Skip skills.
  --no-mcp         Skip MCP servers.
  --no-config      Skip rules, agents, commands, hooks, settings.json, CLAUDE.md.
  --with-runpod    Also install the RunPod plugin (GPU cloud, paid account).

Environment:
  GITHUB_PERSONAL_ACCESS_TOKEN   set it to register the GitHub MCP server
  TODOIST_API_TOKEN              set it to register the Todoist MCP server
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-prereqs) DO_PREREQS=0 ;;
    --no-plugins) DO_PLUGINS=0 ;;
    --no-skills) DO_SKILLS=0 ;;
    --no-mcp) DO_MCP=0 ;;
    --no-config) DO_CONFIG=0 ;;
    --with-runpod) WITH_RUNPOD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown flag: $1"; usage; exit 2 ;;
  esac
  shift
done

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "  \033[32m+\033[0m %s\n" "$*"; INSTALLED+=("$*"); }
have() { printf "  \033[90m= %s\033[0m\n" "$*"; SKIPPED+=("$*"); }
warn() { printf "  \033[33m!\033[0m %s\n" "$*"; PROBLEMS+=("$*"); }
todo() { NEEDS+=("$*"); }
run()  { if [ "$DRY_RUN" = 1 ]; then printf "  \033[90m[dry-run] %s\033[0m\n" "$*"; return 0; fi; "$@"; }

INSTALLED=(); SKIPPED=(); PROBLEMS=(); NEEDS=()

[ "$(uname -s)" = "Darwin" ] || { echo "This script is written for macOS."; exit 1; }

# Installs git (Apple's Command Line Tools), node, uv, gh, jq and ripgrep without Homebrew.
local_tools() {
  local bin="$HOME/.local/bin" arch; arch="$(uname -m)"
  run mkdir -p "$bin"
  # The Command Line Tools bring git and python3. Apple's installer is a dialog, not a password.
  if ! xcode-select -p >/dev/null 2>&1; then
    run xcode-select --install >/dev/null 2>&1
    warn "BLOCKED: click Install in the Command Line Tools window that just opened, wait for it to finish (5 to 15 min), then run ./install.sh again"
    [ "$DRY_RUN" = 1 ] || exit 0
  fi
  have "git $(git --version 2>/dev/null | awk '{print $3}')"
  local gharch=amd64 nodearch=x64 rgarch=x86_64
  [ "$arch" = arm64 ] && { gharch=arm64; nodearch=arm64; rgarch=aarch64; }
  # latest_asset <owner/repo> <regex>: download URL of the newest release asset that matches.
  latest_asset() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | python3 -I -c 'import json,re,sys
for a in json.load(sys.stdin)["assets"]:
    if re.search(sys.argv[1], a["name"]): print(a["browser_download_url"]); break' "$2"; }
  local t; t="$(mktemp -d)"
  if command -v node >/dev/null 2>&1; then have "node"; elif [ "$DRY_RUN" = 1 ]; then run "install node"; else
    local f; f="$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt | awk '{print $2}' | grep "darwin-$nodearch.tar.gz$")"
    curl -fsSL "https://nodejs.org/dist/latest-v22.x/$f" | tar xz -C "$t" && rm -rf "$HOME/.local/node" && mv "$t/${f%.tar.gz}" "$HOME/.local/node" \
      && for b in node npm npx; do ln -sf "$HOME/.local/node/bin/$b" "$bin/$b"; done && ok "node" || warn "node download failed"
  fi
  if command -v uv >/dev/null 2>&1; then have "uv"; else run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh' >/dev/null 2>&1 && ok "uv" || warn "uv download failed"; fi
  if command -v gh >/dev/null 2>&1; then have "gh"; elif [ "$DRY_RUN" = 1 ]; then run "install gh"; else
    curl -fsSL -o "$t/gh.zip" "$(latest_asset cli/cli "macOS_${gharch}\\.zip$")" && (cd "$t" && unzip -q gh.zip) \
      && cp "$t"/gh_*/bin/gh "$bin/gh" && ok "gh" || warn "gh download failed"
  fi
  if command -v jq >/dev/null 2>&1; then have "jq"; elif [ "$DRY_RUN" = 1 ]; then run "install jq"; else
    curl -fsSL -o "$bin/jq" "https://github.com/jqlang/jq/releases/latest/download/jq-macos-$gharch" && chmod +x "$bin/jq" && ok "jq" || warn "jq download failed"
  fi
  if command -v rg >/dev/null 2>&1; then have "ripgrep"; elif [ "$DRY_RUN" = 1 ]; then run "install ripgrep"; else
    curl -fsSL "$(latest_asset BurntSushi/ripgrep "${rgarch}-apple-darwin\\.tar\\.gz$")" | tar xz -C "$t" \
      && cp "$t"/ripgrep-*/rg "$bin/rg" && ok "ripgrep" || warn "ripgrep download failed"
  fi
  rm -rf "$t"
  # New Terminal windows need ~/.local/bin on PATH too.
  local rc="$HOME/.zprofile"
  grep -qs '.local/bin' "$rc" || run sh -c "printf '\nexport PATH=\"\$HOME/.local/bin:\$PATH\"\n' >> '$rc'"
  have "peekaboo and summarize skipped (Homebrew only)"
}

# ── 1. Prerequisites ─────────────────────────────────────────────────────────
if [ "$DO_PREREQS" = 1 ]; then
  bold "1. Prerequisites"
  # A fresh Mac has no Homebrew, and installing it needs the owner's Mac password.
  # Everything that doesn't need it still installs; re-run once brew exists.
  HAVE_BREW=1
  if ! command -v brew >/dev/null 2>&1; then
    [ "${NO_BREW:-0}" = 1 ] || for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
  fi
  # Homebrew dropped Intel Macs (2026-10-23 on an Intel MacBook Pro: "Homebrew on macOS
  # is only supported on Apple Silicon processors!"), so without brew every tool comes
  # from its own official release into ~/.local, with no password.
  export PATH="$HOME/.local/bin:$PATH"
  if [ "${NO_BREW:-0}" = 1 ] || ! command -v brew >/dev/null 2>&1; then
    HAVE_BREW=0
    local_tools
  fi
  [ "$HAVE_BREW" = 1 ] && for pkg in git node uv gh jq ripgrep python@3.13; do
    bin="$pkg"; case "$pkg" in ripgrep) bin=rg ;; python@3.13) bin=python3 ;; esac
    if command -v "$bin" >/dev/null 2>&1; then have "$pkg"; else run brew install "$pkg" >/dev/null && ok "$pkg"; fi
  done
  if [ "$HAVE_BREW" = 1 ]; then
    if command -v peekaboo >/dev/null 2>&1; then have "peekaboo"; else run brew install steipete/tap/peekaboo >/dev/null && ok "peekaboo"; fi
    if command -v summarize >/dev/null 2>&1; then have "summarize"; else run brew install steipete/tap/summarize >/dev/null && ok "summarize"; fi
  fi
  # The Claude desktop app doesn't put a `claude` command on PATH. The official
  # installer needs no password and lands in ~/.local/bin.
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v claude >/dev/null 2>&1; then
    run bash -c 'curl -fsSL https://claude.ai/install.sh | bash' >/dev/null 2>&1 && ok "claude CLI" \
      || { warn "BLOCKED: could not install the claude CLI (curl -fsSL https://claude.ai/install.sh | bash)"; }
  fi
  have "claude $(claude --version 2>/dev/null | head -1)"
fi
export PATH="$HOME/.local/bin:$PATH"
HAVE_CLAUDE=1; command -v claude >/dev/null 2>&1 || HAVE_CLAUDE=0
[ "$HAVE_CLAUDE" = 0 ] && [ "$DRY_RUN" = 0 ] && warn "no claude CLI, so plugins and MCP servers are skipped this run"

if [ "$DRY_RUN" = 0 ]; then
  mkdir -p "$CLAUDE_DIR/skills" "$VENDOR" "$BACKUP_DIR"
  for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md" "$HOME/.claude.json"; do
    [ -f "$f" ] && cp -p "$f" "$BACKUP_DIR/" 2>/dev/null
  done
fi

# ── 2. Plugin marketplaces and plugins ───────────────────────────────────────
MARKETPLACES=(
  "claude-plugins-official anthropics/claude-plugins-official"
  "humanizer blader/humanizer"
)
PLUGINS=(
  context7@claude-plugins-official
  playwright@claude-plugins-official
  serena@claude-plugins-official
  vercel@claude-plugins-official
  railway@claude-plugins-official
  expo@claude-plugins-official
  security-guidance@claude-plugins-official
  hookify@claude-plugins-official
  claude-md-management@claude-plugins-official
  typescript-lsp@claude-plugins-official
  pyright-lsp@claude-plugins-official
  swift-lsp@claude-plugins-official
  session-report@claude-plugins-official
  feature-dev@claude-plugins-official
  frontend-design@claude-plugins-official
  humanizer@humanizer
)
if [ "$WITH_RUNPOD" = 1 ]; then
  MARKETPLACES+=("runpod runpod/runpod-plugins-official")
  PLUGINS+=(runpod@runpod)
fi

if [ "$DO_PLUGINS" = 1 ] && [ "$HAVE_CLAUDE" = 1 ]; then
  bold "2. Plugin marketplaces and plugins"
  mp_list="$(claude plugin marketplace list 2>/dev/null)"
  for entry in "${MARKETPLACES[@]}"; do
    name="${entry%% *}"; repo="${entry#* }"
    if grep -qw -- "$name" <<<"$mp_list"; then have "marketplace $name"
    elif run claude plugin marketplace add "$repo" >/dev/null 2>&1; then ok "marketplace $name"
    else warn "marketplace $name ($repo) failed to add"; fi
  done
  pl_list="$(claude plugin list 2>/dev/null)"
  for p in "${PLUGINS[@]}"; do
    if grep -qF -- "$p" <<<"$pl_list"; then have "plugin $p"
    elif run claude plugin install "$p" >/dev/null 2>&1; then ok "plugin $p"
    else warn "plugin $p failed to install (try: claude plugin install $p)"; fi
  done
  todo "Vercel: run /mcp in Claude Code, pick vercel, sign in (free Hobby account works)"
  todo "Railway: run /mcp, pick railway, sign in (trial credit, then paid)"
  todo "Expo: run /mcp, pick expo, sign in (free account)"
  todo "Context7: run /mcp, pick context7, sign in (free)"
  [ "$WITH_RUNPOD" = 1 ] && todo "RunPod: run /mcp, pick runpod, sign in (paid, pay as you go)"
fi

# ── 3. Skills ────────────────────────────────────────────────────────────────
# Clone or update a repo under $VENDOR. Updates only when the clone is clean.
# Extra arguments are folders for a sparse checkout, for repos too big to clone whole.
fetch_repo() {
  local name="$1" url="$2" dir="$VENDOR/$1"; shift 2
  if ! command -v git >/dev/null 2>&1 || ! git --version >/dev/null 2>&1; then
    # No git yet (fresh Mac). A sparse source is too big to pull as a tarball, so it waits.
    [ -d "$dir" ] && return 0
    [ $# -gt 0 ] && { warn "$name waits for git (re-run after Homebrew)"; return 1; }
    # codeload's HEAD tarball needs no branch name, so nothing from the network reaches a shell string.
    local repo="${url#https://github.com/}"
    case "$repo" in *[!A-Za-z0-9._/-]*) warn "bad repo url $url"; return 1;; esac
    run mkdir -p "$dir" && { [ "$DRY_RUN" = 1 ] || curl -fsSL "https://codeload.github.com/$repo/tar.gz/HEAD" | tar xz -C "$dir" --strip-components 1; } \
      || { warn "could not download $url"; return 1; }
    return 0
  fi
  if [ -d "$dir/.git" ]; then
    if [ -z "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
      run git -C "$dir" pull --ff-only --quiet >/dev/null 2>&1 || true
    fi
  else
    if [ $# -gt 0 ]; then
      run git clone --depth 1 --filter=blob:none --sparse --quiet "$url" "$dir" >/dev/null 2>&1 \
        && run git -C "$dir" sparse-checkout set "$@" >/dev/null 2>&1 \
        || { warn "could not clone $url"; return 1; }
    else
      run git clone --depth 1 --quiet "$url" "$dir" >/dev/null 2>&1 || { warn "could not clone $url"; return 1; }
    fi
  fi
  return 0
}

# Symlink one skill folder into ~/.claude/skills unless that name is taken.
link_skill() {
  local src="$1" name="${2:-$(basename "$1")}" dst="$CLAUDE_DIR/skills/${2:-$(basename "$1")}"
  if [ -e "$dst" ] || [ -L "$dst" ]; then have "skill $name (you already have one)"; return; fi
  if [ "$DRY_RUN" = 0 ] && [ ! -f "$src/SKILL.md" ]; then warn "skill $name: no SKILL.md at $src"; return; fi
  run ln -s "$src" "$dst" && ok "skill $name"
}

AGENT_SCRIPTS=(agent-transcript browser-use create-cli domain-dns-ops github-author-context
  github-deep-review github-project-triage instruments-profiling mac-maintenance
  markdown-converter native-app-performance npm obsidian openai-image-gen oracle
  project-structure release-mac-app reminders skill-cleaner ssh-doctor swift-concurrency-expert
  swiftui-liquid-glass swiftui-performance-audit swiftui-view-refactor things-todo
  video-transcript-downloader vm-lab wrangler xcode-sync)
ANTHROPIC_SKILLS=(docx pdf xlsx pptx skill-creator mcp-builder webapp-testing)
WATCH_SKILLS=(watch watching-videos video-memory configuring-vision asking-with-evidence
  extracting-structure learning-from-mistakes recovering-from-errors sharing-results the-loop)

if [ "$DO_SKILLS" = 1 ]; then
  bold "3. Skills"
  fetch_repo agent-scripts https://github.com/steipete/agent-scripts \
    && for s in "${AGENT_SCRIPTS[@]}"; do link_skill "$VENDOR/agent-scripts/skills/$s"; done
  fetch_repo anthropic-skills https://github.com/anthropics/skills \
    && for s in "${ANTHROPIC_SKILLS[@]}"; do link_skill "$VENDOR/anthropic-skills/skills/$s"; done
  fetch_repo avoid-ai-writing https://github.com/conorbronsdon/avoid-ai-writing \
    && link_skill "$VENDOR/avoid-ai-writing" avoid-ai-writing
  fetch_repo no-ai-slop https://github.com/petergyang/no-ai-slop \
    && link_skill "$VENDOR/no-ai-slop/skills/no-ai-slop"
  fetch_repo carlton-skills https://github.com/31Carlton7/skills \
    && link_skill "$VENDOR/carlton-skills/deslop"
  fetch_repo awesome-llm-apps https://github.com/Shubhamsaboo/awesome-llm-apps \
    agent_skills/first-reader agent_skills/thinking-out-loud \
    && for s in first-reader thinking-out-loud; do link_skill "$VENDOR/awesome-llm-apps/agent_skills/$s"; done
  fetch_repo watch-skill https://github.com/oxbshw/watch-skill \
    && for s in "${WATCH_SKILLS[@]}"; do link_skill "$VENDOR/watch-skill/skills/$s"; done

  # YouTube transcripts: its own installer adds the yt-transcript CLI, the skill,
  # and one UserPromptSubmit hook (appended to settings.json after a backup).
  # Run it only when none of those are already present, so it can't overwrite yours.
  if command -v yt-transcript >/dev/null 2>&1 || [ -e "$CLAUDE_DIR/skills/youtube-transcripts" ] \
     || [ -e "$CLAUDE_DIR/hooks/youtube-transcript-ready.sh" ]; then
    have "youtube-transcripts (already present)"
  elif fetch_repo claude-youtube-transcripts https://github.com/calebnewtonusc/claude-youtube-transcripts; then
    if [ "$DRY_RUN" = 1 ]; then run "$VENDOR/claude-youtube-transcripts/install.sh"
    else (cd "$VENDOR/claude-youtube-transcripts" && ./install.sh 2>&1 | sed "s/^/    /") && ok "youtube-transcripts (yt-transcript CLI + skill)" || warn "youtube-transcripts installer failed"; fi
  fi

  # Skills that ship inside this repo, picked from Caleb's own kit.
  for d in "$HERE"/skills/*/; do link_skill "${d%/}"; done
fi

# ── 4. MCP servers (user scope, so every project sees them) ──────────────────
# Reads ~/.claude.json directly: `claude mcp get` health-checks the server, which
# starts every npx and uvx server just to ask whether it exists.
mcp_has() {
  python3 -I -c 'import json,os,sys
try: d=json.load(open(os.path.expanduser("~/.claude.json")))
except Exception: sys.exit(1)
sys.exit(0 if sys.argv[1] in (d.get("mcpServers") or {}) else 1)' "$1"
}
mcp_add() {
  local name="$1"; shift
  if mcp_has "$name"; then have "mcp $name"; return; fi
  run claude mcp add -s user "$name" "$@" >/dev/null 2>&1 && ok "mcp $name" || warn "mcp $name failed to add"
}

if [ "$DO_MCP" = 1 ] && [ "$HAVE_CLAUDE" = 1 ]; then
  bold "4. MCP servers"
  mcp_add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
  mcp_add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$HOME/code" "$HOME/Downloads"
  mcp_add fetch -- uvx mcp-server-fetch
  mcp_add time -- uvx mcp-server-time
  mcp_add git -- uvx mcp-server-git
  mcp_add chrome-devtools -- npx -y chrome-devtools-mcp@latest --headless
  mcp_add macos-automator -- npx -y @steipete/macos-automator-mcp@latest
  mcp_add chart -- npx -y @antv/mcp-server-chart
  mcp_add blender -- uvx blender-mcp
  command -v peekaboo >/dev/null 2>&1 && mcp_add peekaboo -- peekaboo mcp serve \
    || warn "mcp peekaboo skipped: peekaboo CLI not installed"

  if command -v watch-skill >/dev/null 2>&1; then have "watch-skill CLI"
  else run uv tool install 'watch-skill[standard,ocr,loop,api]' >/dev/null 2>&1 && ok "watch-skill CLI" || warn "watch-skill install failed"; fi
  mcp_add watch-skill -- "$HOME/.local/bin/watch-skill" serve

  # Supabase: the hosted server signs in with OAuth, so no token lands in a file.
  mcp_add supabase --transport http https://mcp.supabase.com/mcp
  todo "Supabase: run /mcp, pick supabase, sign in (free tier works)"

  if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    mcp_add github -e "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
  elif mcp_has github; then have "mcp github"
  else
    warn "mcp github skipped: no GITHUB_PERSONAL_ACCESS_TOKEN"
    todo "GitHub MCP: make a fine-grained token (github.com/settings/personal-access-tokens, only the repos you want) and re-run as GITHUB_PERSONAL_ACCESS_TOKEN=<token> ./install.sh --no-prereqs --no-plugins --no-skills --no-config"
  fi

  if [ -n "${TODOIST_API_TOKEN:-}" ]; then
    mcp_add todoist -e "TODOIST_API_TOKEN=$TODOIST_API_TOKEN" -- npx -y @greirson/mcp-todoist
  elif mcp_has todoist; then have "mcp todoist"
  else
    have "mcp todoist (optional, set TODOIST_API_TOKEN to add it)"
  fi
  todo "Blender MCP: install Blender, then the blender-mcp add-on (github.com/ahujasid/blender-mcp) and click Connect in Blender"
fi

# ── 5. Rules, agents, commands, output styles, hooks, settings, CLAUDE.md ───
copy_if_absent() {
  local src="$1" dst="$2" label="$3"
  if [ -e "$dst" ]; then have "$label (you already have one)"; return; fi
  run mkdir -p "$(dirname "$dst")"
  run cp "$src" "$dst" && ok "$label"
}

if [ "$DO_CONFIG" = 1 ]; then
  bold "5. Rules, agents, commands, hooks, settings"
  for kind in rules agents commands output-styles; do
    for f in "$HERE/claude/$kind"/*.md; do
      copy_if_absent "$f" "$CLAUDE_DIR/$kind/$(basename "$f")" "$kind/$(basename "$f")"
    done
  done

  # Hooks live in their own folder so they can never collide with yours.
  run mkdir -p "$CLAUDE_DIR/hooks/ogo-setup"
  for f in "$HERE/claude/hooks"/*.sh; do
    dst="$CLAUDE_DIR/hooks/ogo-setup/$(basename "$f")"
    if [ -e "$dst" ] && cmp -s "$f" "$dst"; then have "hook $(basename "$f")"
    elif [ -e "$dst" ]; then have "hook $(basename "$f") (you edited it, left alone)"
    else run cp "$f" "$dst" && run chmod +x "$dst" && ok "hook $(basename "$f")"; fi
  done

  # CLAUDE.md: copy the add-on, then add one @import line to yours if it isn't there.
  copy_if_absent "$HERE/claude/CLAUDE-addon.md" "$SETUP_DIR/CLAUDE-addon.md" "CLAUDE-addon.md"
  IMPORT_LINE="@~/.claude/ogo-setup/CLAUDE-addon.md"
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -qF "$IMPORT_LINE" "$CLAUDE_DIR/CLAUDE.md"; then
    have "CLAUDE.md import line"
  elif [ "$DRY_RUN" = 1 ]; then
    run "append '$IMPORT_LINE' to $CLAUDE_DIR/CLAUDE.md"
  else
    printf '\n## Shared setup (added by ogo-claude-setup, delete this line to turn it off)\n%s\n' "$IMPORT_LINE" >> "$CLAUDE_DIR/CLAUDE.md" \
      && ok "CLAUDE.md: one import line appended, your text untouched"
  fi

  echo "  settings.json:"
  dry_flag=""; [ "$DRY_RUN" = 1 ] && dry_flag="--dry-run"
  python3 -I "$HERE/lib/merge_settings.py" "$CLAUDE_DIR/settings.json" \
    "$HERE/claude/settings-fragment.json" "$BACKUP_DIR" $dry_flag \
    || warn "settings.json merge failed, nothing written"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
bold "Done"
echo "  installed: ${#INSTALLED[@]}   already had: ${#SKIPPED[@]}   problems: ${#PROBLEMS[@]}"
[ "$DRY_RUN" = 0 ] && echo "  backups: $BACKUP_DIR"
if [ ${#PROBLEMS[@]} -gt 0 ]; then
  bold "Problems"; for p in "${PROBLEMS[@]}"; do echo "  - $p"; done
fi
if [ ${#NEEDS[@]} -gt 0 ]; then
  bold "Still needs a login or key"; for n in "${NEEDS[@]}"; do echo "  - $n"; done
fi
echo
echo "Restart Claude Code so it loads the new plugins, skills and MCP servers."
