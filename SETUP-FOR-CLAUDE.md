# Prompt: set up my Mac from this repo

This only works in the Claude desktop app's Code tab (the `</>` icon at the top
left). The chat tab can't run anything on the Mac. The short prompt in the
README's "Start here" section points Claude at this file; you can also paste
everything below the line yourself.

---

Set up Claude Code on my Mac from https://github.com/calebnewtonusc/ogo-claude-setup.
This might be a fresh Mac with no Homebrew and no git. Do every step yourself and
only stop for things that need my hands (a click in a window, a browser sign-in).
You don't need any connector in Settings for this, GitHub included, so don't
send me there.

Before every step that opens a window, shows a code, asks for a password or opens
a browser page, tell me first: what will appear, where (it may open behind the
Claude window, so tell me to press Command Tab), and exactly what to click.

1. Get the repo into `~/code/ogo-claude-setup`. Don't run `git` to check: on a Mac
   without Command Line Tools that opens Apple's install window. Run
   `xcode-select -p`; if it succeeds, clone with git. If not, download it:
   `mkdir -p ~/code/ogo-claude-setup && curl -fsSL https://github.com/calebnewtonusc/ogo-claude-setup/archive/refs/heads/main.tar.gz | tar xz -C ~/code/ogo-claude-setup --strip-components 1`
2. Read `README.md` and `install.sh` in full so you know what each step does.
3. Run `./install.sh --dry-run` and tell me in a few lines what it will add.
4. Run `./install.sh`. Don't install Homebrew: it no longer supports Intel Macs,
   and the installer gets every tool without it. If it says the Command Line
   Tools window opened, tell me to click Install, wait for it to finish (5 to 15
   minutes), then run `./install.sh` again.
5. If `gh auth status` fails, sign me in to GitHub. Warn me first that a code is
   coming and a browser page will open. Run `gh auth login --web -h github.com -p https`,
   show me the one-time code from its output, and if no browser page opened, run
   `open https://github.com/login/device`. Wait until `gh auth status` passes.
   I'll need GitHub to push code at the hackathon.
6. Run `./install.sh` once more. If step 5 signed me in, the only new line should
   be `mcp github`. Run it a third time and confirm it reports `installed: 0`.
7. Check, with a pass or fail line each: `claude plugin list` shows the plugins in
   `CATALOG.md`, `claude mcp list` shows the MCP servers, every skill link in
   `~/.claude/skills` resolves, and `~/.claude/settings.json` is valid JSON.
8. Finish with two short lists: logins I still need (with the exact step for
   each, and a warning that each `/mcp` sign-in opens a browser tab), and
   anything that failed (with the error). Then tell me to quit the Claude app
   with Command Q and open it again.
9. Write a PDF to `~/Downloads/ogo setup snags.pdf` listing every snag we hit,
   what caused it and how it got fixed, so I can send it to Caleb. On a fresh
   Mac, write it as a plain text file and convert it with
   `cupsfilter snags.txt > ~/Downloads/"ogo setup snags.pdf"` (built into macOS).

Never put a token or password in a file, and don't commit anything to this repo.
