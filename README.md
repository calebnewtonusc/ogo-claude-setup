# ogo-claude-setup

A Claude Code setup for a Mac, built for a first-time Claude user going into a
hackathon. It adds plugins, MCP servers, skills, coding rules, three subagents,
a status line and a safety hook. It merges into whatever `~/.claude` you already
have and never overwrites your files.

## Start here: use the Code tab

Open the Claude desktop app and click the `</>` icon at the top left to switch to
the Code tab. Do this before you paste anything. The regular chat tab can't touch
your Mac, so it can't run the installer, and it'll tell you to link GitHub in
Settings, Connectors. You don't need that. The installer signs you in to GitHub
itself.

In the Code tab, pick your home folder as the folder to work in, then paste this:

```
Set up Claude Code on my Mac from https://github.com/calebnewtonusc/ogo-claude-setup.
Download it into ~/code/ogo-claude-setup (use curl if git isn't installed yet),
then follow its SETUP-FOR-CLAUDE.md step by step and do every step yourself.
Before anything opens a window, shows me a code, or asks for a password, tell me
what's about to appear and exactly what to click. When you're done, write a PDF
to my Downloads folder called "ogo setup snags.pdf" listing every snag we hit and
how it got fixed, so I can send it to Caleb.
```

That's the whole setup. Claude does every step, checks each one and tells you
which logins are left. You don't need Homebrew (it dropped Intel Macs): the
installer pulls git from Apple's Command Line Tools and node, uv, gh, jq and
ripgrep from their official releases into `~/.local/bin`, no password.

### What will pop up

Claude should warn you before each of these, but here they are so nothing
surprises you:

- **Apple's Command Line Tools window.** Click Install and wait 5 to 15 minutes.
  Claude then runs the installer again.
- **GitHub sign-in.** Claude shows you a code like `ABCD-1234`, and a GitHub page
  opens in your web browser. That page often opens behind the Claude window, so
  press Command Tab to find your browser. Make sure it's signed in to your own
  GitHub account, paste the code, click Authorize, then come back to Claude.
- **Sign-ins inside Claude Code.** After setup, `/mcp` lists servers like Vercel
  and Supabase. Each one you pick opens its own browser tab to sign in. Same
  thing: it may land behind Claude.
- **macOS permission prompts**, the first time Claude uses peekaboo (screenshots)
  or macos-automator (driving Mac apps). They ask for Screen Recording,
  Accessibility or Automation in System Settings. Turn on the one it names.
- **A spoken "Claude needs you".** That's the notification hook, not a bug. It
  talks when Claude is waiting on you.

When it's done, quit the Claude app (Command Q) and open it again, so it loads
the new plugins, skills and MCP servers.

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
- **Hooks**: a status line (folder, branch, model, context used), a warning
  before Claude writes a `.env` file, a slop check after every file edit, and a
  spoken "Claude needs you" when it's waiting on you.
- **Checks on your PATH**: `slop-check` (prose), `code-slop` (code), `ai-scan`,
  and `agent-check`, which runs a typecheck plus slop-check and code-slop on
  staged files.
- **MCP servers and plugins**, each with what it's for, in [CATALOG.md](CATALOG.md).

## By hand

1. `mkdir -p ~/code/ogo-claude-setup && curl -fsSL https://codeload.github.com/calebnewtonusc/ogo-claude-setup/tar.gz/HEAD | tar xz -C ~/code/ogo-claude-setup --strip-components 1 && cd ~/code/ogo-claude-setup`
2. If Homebrew is already installed it gets used, otherwise nothing extra is needed.
3. `./install.sh --dry-run` to preview, then `./install.sh`. Run it twice: the
   second run should add nothing.
4. If `gh auth status` says you're not signed in, run `gh auth login --web`,
   then `./install.sh` once more so the GitHub MCP server gets added.
5. Restart Claude Code, run `/mcp` and sign in to the servers that ask. Each
   sign-in opens a browser tab, which may land behind the Claude window.

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
