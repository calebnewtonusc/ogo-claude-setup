---
paths:
  - "**/agent*/**/*.{ts,js,py}"
  - "**/*agent*.{ts,js,py}"
  - "**/workflows/**/*.{ts,js,py}"
  - "**/evals/**/*"
  - "**/*eval*.{ts,js,py}"
  - "**/tools/**/*.{ts,js,py}"
---

# Agent Architecture

Applies when building agents, workflows, tool-calling code, or evals. Distilled from production practice, not from the marketing around it.

## The layers, and why they get confused

Loop, graph, and harness are three different things and most teams use the words interchangeably, which is why agent debugging feels impossible.

- **Loop** controls repetition: turns, retries, budgets, exits, no-progress detection
- **Graph** controls topology: nodes, edges, state, branches, checkpoints
- **Harness** controls reality: tools, permissions, memory, sandboxes, evals, traces, humans

They nest: prompt inside loop, loop inside graph, graph inside harness. The model is the smallest box in the system. Without the loop layer it never stops, without the graph layer you cannot see why, without the harness layer it can touch anything.

## Graph rules

**An "and then" is only an edge if the next step reads the last step's output.** If no variable crosses between two calls, they are independent and the wait is wasted. Draw it: box is an agent call, arrow is a variable passed from one return into another's prompt.

**Give every node a contract.** Bounded input, bounded output, one job, validated with a JSON schema so mismatches retry instead of handing back free text you parse and pray over.

**Edges are plain code, not agents.** Flatten, dedupe, filter, and map are `results.flatMap(...)` and a `Set`: deterministic, instant, zero tokens. Reserve agents for judgment. A graph where every edge is an agent is paying rent on its own wiring.

**Default to `pipeline()` over `parallel()`.** A barrier makes every item wait for the slowest node in the stage. A pipeline streams each item through all stages independently. Use a barrier only when a stage genuinely needs every prior result at once: cross-set dedupe, early-exit on the total, or a prompt that compares against the other findings. "Cleaner code" and "the stages feel separate" are not reasons.

**Cycles must converge.** For unknown-size discovery, loop until K consecutive rounds surface nothing new. **Dedupe against everything seen, not against confirmed results**, or rejected findings reappear every round and the loop never runs dry.

**Tier the models.** Bounded repetitive nodes (extract, classify) run cheap. Judgment nodes (synthesize, adjudicate) stay expensive. Subagents inherit the session model unless overridden, so a large fan-out bills entirely at your session tier by default.

**Isolate only when nodes write in parallel.** Worktree isolation is a real cost. Use it for the one topology that needs it, not as a default tax.

## Eval rules

**A verdict that does not change the next edge is a report.** This is the whole discipline. The test of whether you have built the layer at all: has any number in your system ever changed control flow?

Wire verdicts to structural actions on the run in progress:

| Verdict             | Action                 |
| ------------------- | ---------------------- |
| low context recall  | reject the handoff     |
| bad tool use        | retry or swap the node |
| hallucination       | quarantine the branch  |
| schema failure      | block the edge         |
| compliance risk     | route to human review  |
| verified completion | terminate the run      |

**Measure the path, not only the answer.** Grading only the final response is how an agent reaches a correct answer through a broken sequence with nobody noticing.

**Faithfulness is the metric nobody watches.** Response quality and faithfulness can sit 50 points apart in the same run: an agent that writes beautifully and is grounded in actual tool output a third of the time. Any agent that calls live tools and is judged on how the reply reads is exposed to this.

**Judge hygiene:**

- Judge from a different model family. A model grades its own writing kinder and shares its own blind spots.
- Rubric is one line: `Pass iff [independently observable successful outcome]`. One verdict, not a bundle of proxy scores.
- Judge decides semantic calls, plain code decides objective ones (did the test pass, does the file exist, did state change).
- Never score on length, keywords, citation count, phrasing, or tool-call count. Reward the shape and the agent learns the shape.
- Pin the judge and log its version. A silently upgrading examiner makes a month of scores incomparable.

**Tests come from logs, not imagination.** Tests you invent protect you from failures you already imagined. Pull ~25 real traces spanning: a normal completion, a user-confirmed answer, a user correction (the correction is a free label), a failed/empty/repeated tool call, and an external failure like a timeout.

Write each up as: observed behavior, comparison, **attribution** (agent, dependency, or unclear), eval candidate. Attribution is where people lose a week: the same lookup called twice with identical arguments is your loop, a 429 is somebody else's limit.

**Never treat the recorded answer as truth.** The trace says what the agent did, never what it should have done.

**Test the test.** Hand the verifier one clearly correct and one plausible-but-wrong fake result. If either goes the wrong way, the rubric is broken, not the agent.

**The first five evals, in order:**

1. Empty tool result: the tool returns nothing, the agent must say so instead of inventing a number
2. Repeated call: same lookup, same arguments, twice. That is a loop and it fails
3. Boundary refusal: asked for something outside permissions, declines cleanly instead of routing around
4. Handoff integrity: what the previous node produced is what the next node reads, nothing invented between
5. Verified completion: done means a real signal says done, never the agent's own word

Size it to stay alive: hold out 300 to 800 cases, keep 500 running under 5 minutes. A suite slower than a coffee break stops being run.

**The counterweight:** 38 green tests can coexist with a completely broken product. Converge on the spec, not on the score.

## Multi-agent: parallelize intelligence, serialize writes

The 2025 argument (Cognition's "don't build multi-agents" vs Anthropic's multi-agent research system) resolved in 2026, and Cognition reversed. The working constraint:

> Multiple agents contribute intelligence to a task while **writes stay single-threaded**.

The failure mode was never parallelism, it was parallel _mutation_. Read, analyze, criticize, and search parallelize safely. Deciding and writing do not.

**Give the reviewer a fresh context on purpose.** A review agent examining a diff with no shared context outperforms one that inherits the writer's context, because it avoids context rot. Reported in production: ~2 bugs caught per PR, 58% of them severe. This is the cheapest available reliability win.

Still unsolved, so do not design as if they were: how a weaker model recognizes its own limits, how a child agent signals a discovery affecting its siblings, and how to hand off context without overwhelming the recipient.

## Context is a budget, not a container

Context rot is architectural, not anecdotal: the transformer's n² pairwise relationships stretch thin over long sequences, and models have no specialized parameters for long-range dependency management. Every token spends from a finite attention budget shared by system prompt, tools, examples, history, and retrieved data.

- **Compaction** for long back-and-forth: keep architectural decisions, unresolved bugs, and implementation details; drop redundant tool output. Tune for recall first, then precision.
- **Structured note-taking** for iterative work: persist outside the window, retrieve on demand.
- **Sub-agents** for parallel exploration: each gets a clean window and returns a distilled **1,000 to 2,000 token** summary, never its transcript.

**System prompt altitude** has failure modes on both ends. Too specific is brittle hardcoded logic; too vague is confusion without signal. Start minimal and add clarity only in response to observed failures.

## Before adding a memory system, prove it is necessary

Most agent-memory benchmarks are saturated: as context windows passed 128k, tasks became solvable with no memory system at all. Run the **Context Saturation Gap** test before accepting the complexity: does retrieval measurably beat putting the relevant material directly in context? If the gap is not large, the index is cost and latency with no payoff.

Two failure modes to watch:

- **Silent structural collapse.** On weaker backbones, memory-maintenance format errors rise sharply (one system went 17.9% to 30.4%). Malformed JSON and hallucinated keys corrupt long-term state while conversational fluency hides it.
- **Lexical metrics misrank.** F1 rewards verbatim overlap and penalizes abstractive memory. Do not tune on it.

## Reliability is compounding error

Per-step accuracy and workflow success are different numbers:

| Per-step | 10-step workflow |
| -------- | ---------------- |
| 85%      | ~20%             |
| 95%      | ~60%             |

Step-level improvements have superlinear payoff, and long autonomous chains are structurally fragile regardless of model quality. Failures rarely surface where they start: a bad assumption at step 3 contaminates step 50 and is only visible at step 200. Shorten chains, checkpoint, and verify at the edges.

## Security is architectural, not filterable

**The lethal trifecta:** private data access + untrusted content exposure + external communication. Any system with all three can be made to exfiltrate by one poisoned input.

**Agents Rule of Two:** an agent should have at most two of (a) processes untrusted input, (b) accesses sensitive systems, (c) changes external state.

Prompt injection is OWASP's #1 LLM risk and remains unsolved. It is not fixable at the filter layer. Mitigate at the architecture layer: least privilege, blast-radius reduction, sandboxing, and human approval on state change. In an agent a successful injection does not corrupt one response, it hijacks the goal and propagates through the orchestration.

## Verification patterns

- **Adversarial verify:** N independent skeptics per finding, each prompted to refute. Keep only if a majority survive.
- **Perspective-diverse verify:** each verifier gets a distinct lens (correctness, security, does-it-reproduce). Diversity catches what N identical checks never will.
- **Judge panel:** N attempts from different angles, parallel scoring, synthesize from the winner while grafting the runners-up.

## Autonomous merge

Trust is actuarial, not a feeling. Compute confidence from four signals, three of which never touch the model: deterministic guardrail result, recent eval trajectory, historical revert rate for this agent on this class of change, and sandbox outcome. Above threshold it merges itself; below, a human gets it with the failing signal named so review starts at the problem.

Turn it on in shadow mode first (score everything, merge nothing, at least 4 hours of real traffic), hold a 2% deviation threshold between automated and human verdicts, and sample traces at 1 to 5%.

## Vercel AI SDK

For any AI feature, stream. Never buffer output.

```typescript
import { streamText } from "ai";
import { anthropic } from "@ai-sdk/anthropic";

const result = streamText({
  model: anthropic("claude-sonnet-5"),
  messages,
  system: "...",
});
return result.toDataStreamResponse();
```

Client side use `useChat` from `ai/react`. For typed JSON use `generateObject` with a Zod schema. For actions use `tool()` with a Zod `parameters` schema and an `execute` function.

**RAG:** chunk, embed, store in pgvector, embed the query, cosine search top-K, inject into the system prompt, stream. Add retrieval evaluation: is it finding the right chunks or just nearby ones?

Always use the latest Claude models. Model ids: `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5`, `claude-haiku-4-5-20251001`.
