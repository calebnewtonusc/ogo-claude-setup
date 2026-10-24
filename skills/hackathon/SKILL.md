---
name: hackathon
description: Win a one-day hackathon with a working demo. Use for picking a direction, splitting work in a team, scoping to the code freeze, building the demo path first, and the 3-minute pitch. Has the FaithTech x Baptize The World rules for Sat 2026-10-24.
---

# Hackathon

A one-day hackathon is judged on a live demo, so the whole day works backwards
from the code freeze.

## The day (FaithTech x Baptize The World, Sat 10/24, Robertson Triangle LA)

- 9:00 doors. The morning is worship, meeting Baptize The World and picking a direction.
- Direction locks before lunch, in the form "We help [audience] to [action] by [tech]".
- Code starts fresh that day. Public repo, test data only, any stack, any AI tools, credit what you used.
- 4:00 code freeze. 4:15 demos: 3 minutes plus 2 of questions, shown live on a phone.
- Judged 1 to 5 on: works across countries and languages on a basic phone, works today,
  built by the whole team, could plug into Baptize The World tomorrow.

The tracks:

1. (Primary) Help a pastor anywhere register their church, get resources and report
   baptisms on the phone they already use, in their own language, so every baptism on
   Pentecost 2027 (May 16) gets counted.
2. Help someone just baptized tell their story in their own words and share it with their church.
3. Help a church walk a newly baptized person through their first 30 days.

## Our build: Anchored (Track 3, first 30 days after baptism)

The repo is `calebnewtonusc/anchored`, a Next.js and TypeScript app on Railway. Read SPEC.md,
TEAM.md and AGENTS.md in the repo before touching anything: they win over this list
if they disagree. Lanes, and nobody edits another lane's files:

- **Ogo (Mac, Claude Code):** the WhatsApp interface, plus the rhythm and behavior of
  the agent toward the baptizee and the baptizer: when it messages each of them, what
  it says after a slip, a hard moment, silence, and on days 7, 14, 21 and 30, how it
  syncs into the dashboard, and what a church can customize. Owns `bridge/`,
  `content/days.json` and `docs/agent-rhythm.md`. Write the rhythm spec first, then
  run the bridge against the dev server with `--log` and prove a round trip from a
  second phone: ANCHORED, YES, a reply, an outbox message.
- **Anthony (Linux, Codex):** the dashboard for ministries, leaders and friends.
  Owns `app/discipler/` and `app/page.tsx`.
- **Caleb:** AI infra, deployment and the Mac HUD. Owns `lib/companion.ts`,
  `lib/engine.ts`, `lib/store.ts`, `os/`, `prompts/` and Railway.

`lib/types.ts` is the shared contract: change it only after the whole team agrees out
loud. Every verse carries its reference and comes from `content/`. Use test phone numbers
in the 555 range only. Turn on the repo's pre-commit checks once per clone with
`git config core.hooksPath .githooks`, and run `scripts/check.sh` before saying a
change is done. Pull before every push: three people push to main today.

## How to run the build

1. **Demo path first.** Write the 3-minute demo as a list of taps before writing code.
   Build only what that list touches. Everything else is a slide or a sentence.
2. **One owner per part.** Each person owns a folder and pushes to main often. Two people
   never edit the same file. Agree on the data shape (a JSON example) in the first 15 minutes.
3. **Fake what isn't judged.** Hardcode the login, seed test data, skip settings pages.
   The judges score "works today", so a real flow on fake data beats a fake flow on real data.
4. **Checkpoint at 2:30.** If the main flow doesn't work end to end, cut scope now.
   Nothing new after 3:30, only fixing and rehearsing.
5. **Deploy early.** Get a public URL by 1:30 even if it's ugly, so the phone demo
   never depends on a laptop.
6. **Rehearse twice on the phone** you'll demo on, with the time running.

## Using Claude for it

- Ask for the smallest version that works first, then iterate. Paste the error, every word.
- Make it run the app and click through the demo path before you call a step done.
- Keep a `DEMO.md` in the repo with the tap list and have Claude check each step still works.

## The pitch (3 minutes)

- 20 sec: who it's for and the moment it helps ("a pastor in Lagos just baptized 12 people").
- 2 min: the live demo, one person all the way through.
- 30 sec: how Baptize The World could plug it in tomorrow, and what's next.
- Say who built what. "Built by the whole team" is a judging line.
