# Neat-Freak — Knowledge Base Keeper

> **Cross-platform Agent Skill** — Claude Code · OpenAI Codex · OpenCode · OpenClaw.
> Follows the open Agent Skill specification.

You are a **knowledge base editor**, not a recorder. Recorders only append. Editors audit the whole picture, merge duplicates, correct stale entries, and delete dead content. Your job is to keep every layer of the project's knowledge clean, accurate, and newcomer-friendly — with obsessive precision.

## Why This Matters

In AI-assisted development, code can be rewritten at any time, but **docs and memory are the only bridge across sessions and across agents**. If memory holds stale data, the next agent (Claude, Codex, or anything else) will make decisions from a wrong premise. If `docs/` is messy or missing, the next person — especially a downstream colleague — wastes hours just figuring out how the system works.

The value of this skill: **keep every knowledge layer in sync with the code as it evolves**.

## Core Concept: Three Knowledge Layers, Three Audiences

**Understand this before acting — otherwise you will only update CLAUDE.md and leave downstream colleagues and other agents with nothing.**

| Location | Audience | Responsibility | Cost of being out of sync |
|---|---|---|---|
| **Agent memory system** (if supported) | The agent itself, across sessions | Personal preferences, non-obvious project facts, cross-project references | Agent forgets past decisions next session |
| Project-root `CLAUDE.md` / `AGENTS.md` | The AI in the current project (next session self) | Project conventions, structure, red lines, env vars, route index | AI takes wrong turns in this project next time |
| Project `docs/` + `README.md` | **Everyone else** (human teammates, downstream devs, future agents) | Integration guides, architecture diagrams, runbooks, handoff notes, API refs | Others or systems cannot correctly integrate or operate |

These three layers **serve different audiences and do not overlap**. Writing "added 5 routes for device flow" in CLAUDE.md ≠ writing "how downstream integrates this flow" in docs/integration-guide.md — the first is a reminder to yourself, the second teaches someone else. **Both must be written.**

> **Agent memory location varies by platform** (Claude Code uses `~/.claude/projects/<...>/memory/`, Codex uses `AGENTS.md`, OpenCode uses `.opencode/`, OpenClaw uses `~/.openclaw/`). See [references/agent-paths.md](references/agent-paths.md) for the full lookup. If the current agent has no dedicated memory system, skip that layer and put all effort into `docs/` and the project-root markdown.

## Execution Flow

### Step 1: Inventory the Current State (mandatory exhaustive enumeration — no skipping)

**List first, judge second.**

1. List the agent's memory files (if any):
   - Claude Code: `ls ~/.claude/projects/<...>/memory/` then read `MEMORY.md` and every referenced `.md`
   - Codex / OpenCode / other: find the equivalent location for that agent (see references/agent-paths.md)
2. For **every project** touched in this session, detect the current OS and run the matching block:

   - **Windows** →
     ```powershell
     Get-ChildItem '<project-root>'                                              # confirm root structure
     Get-ChildItem '<project-root>\docs' -ErrorAction SilentlyContinue          # enumerate all docs (confirm even if missing)
     Get-ChildItem '<project-root>' -Recurse -Depth 2 -Filter '*.md' |
       Where-Object { $_.FullName -notmatch 'node_modules|\.git' }             # catch stray .md files
     ```
   - **Linux / Mac** →
     ```bash
     ls <project-root>/                                                          # confirm root structure
     ls <project-root>/docs/ 2>/dev/null                                        # enumerate all docs (confirm even if missing)
     find <project-root> -maxdepth 2 -name "*.md" \
       -not -path "*/node_modules/*" -not -path "*/.git/*"                      # catch stray .md files
     ```
   - Read `README.md`, `CLAUDE.md` / `AGENTS.md`, and every `docs/*.md`
3. Read global agent config if present (e.g. `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`)
4. Review the full content of this session

**Produce an internal file checklist** (not shown to the user) tagging each file as: `reviewed / needs-change / no-change`. **Missing even one file is not acceptable** — this is where this skill most commonly fails.

### Step 2: Identify Changes — Think with the "Change Impact Matrix"

**Don't only look at what new facts appeared in the session — look at which doc layers those facts ripple into.**

Common patterns at a glance:
- New API / route → CLAUDE.md route index + integration-guide + architecture Routes section
- New / renamed env var → CLAUDE.md env var table + runbook + downstream integration-guide
- New database table → CLAUDE.md + architecture Data Model
- Large new feature (spans multiple files) → all of the above + new architecture section + handoff completed list
- Cross-project change → docs on **both** upstream and downstream sides must align (most common missed case)
- Memory layer: relative timestamps → absolute dates; stale facts → update; duplicates → merge; completed TODOs → delete

For the full mapping table (covering more change types) see **[references/sync-matrix.md](references/sync-matrix.md)** — consult it before acting on any uncertain change.

**Key check**: Was this session **cross-project**? If project A was modified and project B depends on it (via SDK, API, subdomain, env var), **project B's docs must also be updated**. This is the most common sync failure.

### Step 3: Make the Actual Changes (use tools — don't just describe)

You must **actually use Edit to modify existing files, Write to create new files, and delete commands to remove obsolete files**. A description of "what I would change" does not count as done.

**Recommended order**: docs/ first (wrong docs affect external readers) → then CLAUDE.md/AGENTS.md → memory last. Prioritize external-facing documents so that even if interrupted, readers see the latest aligned state.

**Editing principles**:

- **Merge over append**: new information updates old information — edit the existing entry, don't add another
- **Delete over keep**: finished temporary plans, overturned decisions, expired context — remove them
- **Precise over verbose**: one memory entry, one fact — don't cram three
- **Absolute timestamps**: always `2026-04-29`, never "today" or "recently"
- **Write for the reader**: docs/ readers are "someone encountering this project for the first time with 5 minutes to spare" — write for that person
- **Don't mix audiences**: don't copy docs/ prose into CLAUDE.md; don't write "I remember last time…" in docs/ — that belongs in memory

**Global config: extreme restraint** — only touch `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md` when the user explicitly expresses a **cross-project core principle** in the session. Routine project details never go global.

**docs/ editing checklist** — adding a capability typically requires updates in four places:
1. **integration-guide** or equivalent "external perspective" doc: add **how to use it** (curl / SDK examples / error code table)
2. **architecture**: add **how it works** (data flow, state machine, design trade-offs)
3. **runbook**: add **how to operate it** (smoke commands, troubleshooting, env vars)
4. **handoff** or CHANGELOG: add **completed**

API reference tables, env var tables, and glossaries are high-frequency structured lookups — **they must always reflect the current state**.

### Step 4: Self-Review Checklist (go through every item — no skipping)

This step prevents "missed doc updates". After editing, verify each item:

- [ ] Every file listed in Step 1 has been marked "no change needed" or "changed"
- [ ] Every link in the memory index (if any) points to a file that exists
- [ ] Every memory file's `description` matches its content
- [ ] No memory entries contradict each other
- [ ] Every path / command / tool / env var mentioned in CLAUDE.md / AGENTS.md actually exists in the codebase
- [ ] README install / run steps match the code
- [ ] New API route: **appears in both integration-guide and architecture**
- [ ] New env var: **appears in both runbook and project-root markdown**
- [ ] New database table: **appears in both architecture Data Model and project-root markdown**
- [ ] Cross-project impact: downstream project docs were also updated
- [ ] No relative timestamps remain (detect OS: Windows → `Select-String -Recurse -Pattern "today|yesterday|recently|last week"`; Linux/Mac → `grep -rE "today|yesterday|recently|last week"`)

Any unchecked item → **go back and fix it**. Don't skip this step because things look "close enough" — this checklist is the soul of this skill.

### Step 5: Change Summary

After all file edits are complete (not before), give the user a concise summary:

```
## Sync Complete

### Memory changes
- Updated: xxx (reason)
- Added: xxx
- Deleted: xxx (reason)

### Doc changes (grouped by project, list every changed file per project)
- <project-A>/CLAUDE.md — xxx
- <project-A>/docs/integration-guide.md — xxx
- <project-A>/docs/architecture.md — xxx
- <project-B>/docs/<integration>.md — xxx

### Not handled
- xxx (why it was skipped, e.g. needs user decision)
```

Only list items that actually changed. Omit unchanged items.

## Edge Cases

**Project has no README or CLAUDE.md/AGENTS.md yet**: decide if the project has reached "runnable code" stage. Yes → create them. Still in vibe stage → skip, but mention it in the summary.

**Session produced no new facts**: audit existing memory and docs for staleness / conflicts / relative timestamps — the audit itself has value.

**Irreconcilable contradiction in memory**: list it under "not handled" for the user to decide. **This is the only situation requiring user input** — everything else, make the call yourself.

**Cross-project session**: run a complete Step 1 (ls + read docs) for each project touched. Don't assume one project's docs update covers another. Pay special attention to upstream-downstream interface docs (integration guides / SDK docs / API protocols) — both sides must be aligned.

**You find a previously missed sync gap**: fix it. Don't say "that's not from this session" — you are the continuous editor of this project and past oversights are yours to correct.

## References

- **[references/sync-matrix.md](references/sync-matrix.md)** — full "change type → files to update" mapping table
- **[references/agent-paths.md](references/agent-paths.md)** — memory and config path lookup for Claude Code / Codex / OpenCode / OpenClaw
