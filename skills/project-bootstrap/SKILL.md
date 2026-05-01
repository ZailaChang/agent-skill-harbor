---
name: project-bootstrap
description: >
  Sets up a new VS Code project by importing relevant skills from the global skill
  pool into the project's local .github/skills/. Two modes: (A) analyzes existing
  docs/specs to recommend skills automatically, (B) lists all global skills for
  manual selection when starting from scratch.
  MUST trigger when the user says: "new project", "open project", "bootstrap",
  "import skills", "setup project", "setup skills", "初始化專案", "新專案", "專案 setup",
  "幫我選 skills", "import 哪些 skills", "/bootstrap", "/project-setup",
  or any phrase indicating a new project is being started in VS Code.
---

# Project Bootstrap — Skill Importer

> **Purpose:** When opening a new VS Code project, select and copy relevant skills
> from the global pool into the project so the agent has the right tools available.
>
> **Global skill pool:** `<SKILLS_ROOT>/skills/`  *(set by `bash setup.sh` after cloning agent-skill-harbor)*
> **Install target:** `<new-project-root>/.github/skills/`

---

## Two Modes

```
Open new project in VS Code
         │
         ├── .github/skills/ already populated?
         │         YES ──→ STOP: run /skills (skill-sync) instead
         │         NO  ──→ continue
         │
         ├── Has docs / spec / README with content?
         │         YES ──→ Mode A: Analyze & Recommend
         │         NO  ──→ Mode B: Manual Selection
```

---

## Pre-flight Check

```bash
ls <project-root>/.github/skills/ 2>/dev/null
```

If `.github/skills/` already has skill folders → stop and say:
> "This project already has skills installed. Run `/skills` to audit and update them."

Otherwise proceed to Mode A or B.

---

## Mode A — Analyze & Recommend

**Trigger:** Project has any of: `README.md`, `SPEC.md`, `docs/`, `IMPLEMENTATION_PLAN.md`,
`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.

### Step A1: Gather Project Signals

Read first 60 lines of each available file:

| What to look for | Files |
|-----------------|-------|
| Project type / stack | `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml` |
| Architecture / domain | `README.md`, `SPEC.md`, `docs/architecture*.md` |
| Dependencies | `requirements.txt`, `*.lock` |
| Dev maturity | presence of `tests/`, `.github/workflows/` |
| Domain keywords | API, UI, CLI, database, auth, deploy, performance, browser |

### Step A2: Map Signals → Skills

| Signal detected | Recommended skills |
|-----------------|--------------------|
| UI / frontend / components | `frontend-ui-engineering` |
| API / routes / endpoints | `api-and-interface-design` |
| `tests/` dir or testing mentioned | `test-driven-development` |
| Browser / web runtime | `browser-testing-with-devtools` |
| Auth / security mention | `security-and-hardening` |
| CI / GitHub Actions / pipeline | `ci-cd-and-automation` |
| `docs/` or ADR mention | `documentation-and-adrs` |
| Performance / latency mention | `performance-optimization` |
| SPEC.md or requirements doc | `spec-driven-development` |
| IMPLEMENTATION_PLAN or task list | `planning-and-task-breakdown` |
| Complex / unclear codebase | `context-engineering` |
| External APIs / SDK usage | `source-driven-development` |
| Migration / deprecation notes | `deprecation-and-migration` |
| Code complexity concern | `code-simplification` |
| Review / quality gate | `code-review-and-quality` |
| Any project (always) | `using-agent-skills`, `debugging-and-error-recovery`, `incremental-implementation`, `neat-freak`, `skill-sync` |

### Step A3: Present Recommendation

```
📦 Project Bootstrap — Skill Recommendation
   Analyzed: README.md, SPEC.md, pyproject.toml

   ✅ RECOMMENDED (auto-selected):
    1. using-agent-skills            — meta-skill, always needed
    2. incremental-implementation    — detected implementation plan
    3. api-and-interface-design      — API/routes detected in spec
    4. test-driven-development       — tests/ directory found
    5. debugging-and-error-recovery  — always useful
    6. neat-freak                    — session cleanup
    7. skill-sync                    — keep skills in sync

   ➕ OPTIONAL (select by number):
    8. spec-driven-development       — SPEC.md found, useful for iteration
    9. security-and-hardening        — auth mention in README

   ❌ NOT RECOMMENDED (no signals):
   - frontend-ui-engineering         (no UI signals)
   - browser-testing-with-devtools   (no browser signals)

   Press Enter to accept ✅, or type numbers to toggle (e.g. +8 -5):
```

Wait for input → apply toggles → go to **Install Step**.

---

## Mode B — Manual Selection

**Trigger:** No docs/spec found, or user says "blank project" / "from scratch".

```
📦 Project Bootstrap — Select Skills to Import
   Global pool: <SKILLS_ROOT>/skills/  (N skills)

   ALWAYS RECOMMENDED (pre-selected ✅):
   ✅  1. using-agent-skills            — meta-skill
   ✅  2. debugging-and-error-recovery  — systematic debugging
   ✅  3. neat-freak                    — end-of-session sync
   ✅  4. skill-sync                    — keep skills aligned

   BY PHASE — type number to toggle:
   Define:
   [ ]  5. idea-refine
   [ ]  6. spec-driven-development
   Plan:
   [ ]  7. planning-and-task-breakdown
   Build:
   [ ]  8. incremental-implementation
   [ ]  9. frontend-ui-engineering
   [ ] 10. api-and-interface-design
   [ ] 11. context-engineering
   [ ] 12. source-driven-development
   Verify:
   [ ] 13. test-driven-development
   [ ] 14. browser-testing-with-devtools
   Review:
   [ ] 15. code-review-and-quality
   [ ] 16. code-simplification
   [ ] 17. security-and-hardening
   [ ] 18. performance-optimization
   Ship:
   [ ] 19. ci-cd-and-automation
   [ ] 20. documentation-and-adrs
   [ ] 21. deprecation-and-migration
   [ ] 22. git-workflow-and-versioning

   Shortcuts:
     "all"  → select all
     "min"  → pre-selected only (1-4)
     "web"  → web stack (1-4, 9, 10, 13, 14, 15, 17)
     "api"  → API stack (1-4, 6, 7, 8, 10, 13, 15, 17, 20)
     "data" → backend/data stack (1-4, 6, 7, 8, 12, 13, 15, 17)
   Enter  → confirm
```

Wait for input → go to **Install Step**.

---

## Install Step

### Step 0: Create .github/copilot-instructions.md (ALWAYS FIRST)

Before copying any skills, create `.github/copilot-instructions.md` in the project root.
This file is loaded by VS Code Copilot in EVERY chat session for this workspace — it is
the bridge that makes the agent aware of the skill pool even before any skills are installed.

```bash
mkdir -p <project-root>/.github/
```

Write `.github/copilot-instructions.md` with this content (substituting actual project path):

```markdown
<!-- Auto-generated by project-bootstrap. Do not delete. -->
# Agent Instructions for This Project

## Skill Pool
This project uses a structured skill system.
- **Global pool:** `<SKILLS_ROOT>/skills/`  *(set by setup.sh / setup.ps1)*
- **Project skills:** `.github/skills/` (installed skills for this project)

## Mandatory Triggers
- "setup skills" / "/bootstrap" → read and follow `<SKILLS_ROOT>/skills/project-bootstrap/SKILL.md`
- "sync skills" / "/skills" → read and follow `.github/skills/skill-sync/SKILL.md`
- "整理一下" / "/neat" / "sync up" → read and follow `.github/skills/neat-freak/SKILL.md`

## Rule
Before any non-trivial task, check if `.github/skills/<relevant-skill>/SKILL.md` exists
and follow it. Skills encode the correct process — do not improvise without checking first.
```

### Step 1: Copy Selected Skills

```bash
cp -r <SKILLS_ROOT>/skills/<skill-name>/ \
       <project-root>/.github/skills/<skill-name>/
```

Repeat for each selected skill.

### Step 2: Finalize using-agent-skills

1. Copy `using-agent-skills/SKILL.md` from global (if selected).
2. **Prune the project's `using-agent-skills/SKILL.md`** — remove decision tree
   entries and Quick Ref rows for skills that were NOT installed. Keep the project
   registry lean: only reference what's actually there.

---

## Summary Output

```
## Project Bootstrap Complete

Project: <project-root>
Mode: A (analyzed) / B (manual)

Installed (N skills):
- using-agent-skills
- incremental-implementation
- …

Skipped:
- frontend-ui-engineering
- …

Next steps:
  /skills   → add more skills any time
  /neat     → sync docs at end of session
  Skills at: <project-root>/.github/skills/
```

---

## What This Skill Does NOT Do

- Does not modify global skill files
- Does not remove skills already installed in the project (use skill-sync for that)
- Does not create new skills
- Does not touch project source code — only `.github/skills/`

For project-wide doc sync → **neat-freak**.
To add skills to an existing project → **skill-sync**.
