# Prompt: set up my Mac from this repo

Paste this into the Claude app's Code tab (or just paste the repo link and say
"set me up from this"):

---

Set up Claude Code on my Mac from https://github.com/calebnewtonusc/ogo-claude-setup.
This might be a fresh Mac with no Homebrew and no git. Do every step yourself and
only stop for things that need my hands (my Mac password, a browser sign-in).

1. Get the repo into `~/code/ogo-claude-setup`. If `git --version` works, clone it.
   If not, download it: `mkdir -p ~/code/ogo-claude-setup && curl -fsSL https://github.com/calebnewtonusc/ogo-claude-setup/archive/refs/heads/main.tar.gz | tar xz -C ~/code/ogo-claude-setup --strip-components 1`
2. Read `README.md` and `install.sh` in full so you know what each step does.
3. Run `./install.sh --dry-run` and tell me in a few lines what it will add.
4. Run `./install.sh`. Don't install Homebrew: it no longer supports Intel Macs,
   and the installer gets every tool without it. If a Command Line Tools window
   opens, tell me to click Install, wait for it to finish, then run `./install.sh` again.
5. Run `./install.sh` once more and confirm it reports nothing new.
6. Check, with a pass or fail line each: `claude plugin list` shows the plugins in
   `CATALOG.md`, `claude mcp list` shows the MCP servers, every skill link in
   `~/.claude/skills` resolves, and `~/.claude/settings.json` is valid JSON.
7. If `gh auth status` fails, run `gh auth login --web` and wait for me to finish
   in the browser. I'll need GitHub to push code at the hackathon.
8. Finish with two short lists: logins I still need (with the exact step for
   each), and anything that failed (with the error).

Never put a token or password in a file, and don't commit anything to this repo.
