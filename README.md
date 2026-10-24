# ogo-claude-setup

A Claude Code setup for a Mac, built for a first-time Claude user going into a
hackathon. It adds plugins, MCP servers, skills, coding rules, three subagents,
a status line and a safety hook. It merges into whatever `~/.claude` you already
have and never overwrites your files.

## Fastest way

Open the Claude app, go to the Code tab, paste this repo's link and say "set me
up from this". Or paste [SETUP-FOR-CLAUDE.md](SETUP-FOR-CLAUDE.md). Claude does
every step, checks each one and tells you which logins are left. The only step
that needs you is Homebrew, because it asks for your Mac password.

## What you get

- **Skills** Claude uses on its own when they fit: debugging, deep-research,
  reviewing-changes, shipping, interface (UI that doesn't look generated),
  diagram, clone-site, repo-health, skill-forge (write your own skills),
  study-guide, manim, video-edit, and a `hackathon` skill with the day's rules,
  tracks and a build plan. Plus document skills (docx, pdf, xlsx, pptx), Mac and
  dev skills, video skills and writing editors from the sources below.
- **Rules** for security, TypeScript, naming, UI and deploys, so code comes out
  right the first time.
- **Subagents**: code-reviewer, debugger, explorer.
- **Hooks**: a status line (folder, branch, model, context used) and a warning
  before Claude writes a `.env` file.
- **MCP servers and plugins**, each with what it's for, in [CATALOG.md](CATALOG.md).

## By hand

1. Homebrew from https://brew.sh (needs your Mac password).
2. `git clone https://github.com/calebnewtonusc/ogo-claude-setup ~/code/ogo-claude-setup && cd ~/code/ogo-claude-setup`
3. `./install.sh --dry-run` to preview, then `./install.sh`. Run it twice: the
   second run should add nothing.
4. Restart Claude Code, run `/mcp` and sign in to the servers that ask.

Sections run on their own: `--no-prereqs`, `--no-plugins`, `--no-skills`,
`--no-mcp`, `--no-config`. `./install.sh --help` lists them. `tests/smoke.sh`
dry-runs the installer in an empty home folder.

## What it never touches

- A skill, rule, agent, command or MCP server whose name you already have.
- Your CLAUDE.md text. One `@~/.claude/ogo-setup/CLAUDE-addon.md` import line
  is appended. Delete it to turn the add-on off.
- Your settings.json values. New hooks and deny rules are appended, and
  settings.json, CLAUDE.md and `~/.claude.json` are backed up to
  `~/.claude/backups/ogo-setup-<timestamp>/` first.

## Skill sources

- [steipete/agent-scripts](https://github.com/steipete/agent-scripts): dev and Mac skills
- [anthropics/skills](https://github.com/anthropics/skills): docx, pdf, xlsx, pptx, skill-creator, mcp-builder, webapp-testing
- [oxbshw/watch-skill](https://github.com/oxbshw/watch-skill): video skills
- [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing), [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop), [31Carlton7/skills](https://github.com/31Carlton7/skills)
- [Shubhamsaboo/awesome-llm-apps](https://github.com/Shubhamsaboo/awesome-llm-apps): first-reader, thinking-out-loud
- [calebnewtonusc/claude-youtube-transcripts](https://github.com/calebnewtonusc/claude-youtube-transcripts): `yt-transcript`
- The `skills/` folder here: picked from Caleb's own kit

## Uninstall

- Skills: delete the symlinks in `~/.claude/skills` that point into `~/.claude/ogo-setup/` or this repo
- Hooks and add-on: delete `~/.claude/ogo-setup/` and `~/.claude/hooks/ogo-setup/`, and the import line in CLAUDE.md
- settings.json: restore it from `~/.claude/backups/ogo-setup-*/`

All glory to God! ✝️❤️
