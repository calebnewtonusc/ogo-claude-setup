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
