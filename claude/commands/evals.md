---
description: Build the first five agent evals from real production traces, not imagined ones.
argument-hint: "[agent path or repo]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

Stand up an eval suite for the agent at $1. Follow the discipline in `~/.claude/rules/agent-architecture.md`.

**Step 1: mine real traces.** Find the logs. Pull ~25 complete traces chosen so good and bad sit next to each other: a normal completion, a user-confirmed answer, a user correction (the correction is a free label), a run with a failed/empty/repeated tool call, and a run with an external failure like a timeout or 429.

Write each up as: observed behavior, comparison, **attribution** (agent / dependency / unclear), eval candidate.

Do not invent test cases. Tests you imagine protect you from failures you already imagined.

**Step 2: build these five, in order.**
1. Empty tool result — the tool returns nothing, the agent must say so instead of inventing a value
2. Repeated call — same lookup, same arguments, twice. That is a loop and it fails
3. Boundary refusal — asked for something outside permissions, declines cleanly instead of routing around
4. Handoff integrity — what the previous node produced is what the next node reads, nothing invented between
5. Verified completion — done means a real signal says done, never the agent's own word

**Step 3: judge hygiene.**
- Judge from a different model family than the generator
- Rubric is one line: `Pass iff [independently observable successful outcome]`
- Code decides objective calls, the judge decides only semantic ones
- Never score on length, keywords, or similarity to a reference
- Pin the judge version and log it

**Step 4: test the test.** Hand the verifier one clearly correct and one plausible-but-wrong fake result. If either goes the wrong way, the rubric is broken, not the agent.

**Step 5: wire the verdict to control flow.** A score that changes nothing is analytics. Map verdicts to actions: reject the handoff, retry or swap the node, quarantine the branch, block the edge, route to human, terminate.

Keep the whole suite under 5 minutes. A suite slower than a coffee break stops being run.
