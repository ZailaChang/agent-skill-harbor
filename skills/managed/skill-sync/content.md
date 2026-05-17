
# Skill Sync — Skills Registry Aligner

> **Cross-platform Agent Skill** — Claude Code · OpenAI Codex · OpenCode · OpenClaw.
>
> **Scope: skills only.** This skill touches exactly two things:
> 1. The `using-agent-skills/SKILL.md` decision tree + quick-reference table
> 2. Any other index files that enumerate skills (e.g., `copilot-instructions.md`)
>
> It does NOT touch project docs, agent memory, README, or CLAUDE.md.
> For full project sync, use **neat-freak** instead.

## Why This Exists

As skills accumulate, `using-agent-skills/SKILL.md` goes stale:
- New skills added to disk are invisible to the decision tree
- Renamed or removed skills leave ghost entries
- Descriptions drift from reality

This skill fixes that in one focused pass — surgical, not sweeping.
---

## Execution Flow

### Step 1: Enumerate — What's Actually on Disk

Detect OS, then run the matching block:

- **Windows** →
  ```powershell
  Get-ChildItem '<SKILLS_ROOT>' -Directory | Select-Object -ExpandProperty Name
  ```
- **Linux / Mac** →
  ```bash
  ls <SKILLS_ROOT>/
  ```

For each subdirectory, read its `SKILL.md` frontmatter:

Build an **on-disk registry** list. Example:

| Folder | name | description (first sentence) |
|--------|------|------------------------------|
| neat-freak/ | neat-freak | End-of-session knowledge cleanup… |
| skill-sync/ | skill-sync | Dynamically reconciles the skills registry… |
| … | … | … |

### Step 2: Enumerate — What's Declared in using-agent-skills

Read `using-agent-skills/SKILL.md` and extract:

1. **Decision tree** entries (the `──→ skill-name` lines)
2. **Lifecycle Sequence** numbered list
3. **Quick Reference** table rows

Build a **declared registry** list of all skill names referenced.

### Step 3: Diff — Find Gaps

Compute three sets:

| Category | Meaning | Action |
|----------|---------|--------|
| **Missing** | On disk, not in declared registry | Add to decision tree + Quick Ref |
- `name:` — canonical identifier
- `description:` — one-liner for the quick-reference table
| **Description drift** | Description differs meaningfully | Update Quick Ref one-liner |

If diff is empty → report "already in sync, no changes needed" and stop.

#### Step 3a: Interactive Resolution for Stale Skills

For **each** stale skill found, before touching any file, present this prompt to the user:

```
⚠️  Stale skill detected: `<skill-name>`
| **Stale** | In declared registry, not on disk at `<SKILLS_ROOT>/` | **STOP — ask user (see Step 3a)** |

    I also checked known staging areas and found:
    → <path-if-found-elsewhere>  (or "not found anywhere")

    What should I do?
    Declared in using-agent-skills/SKILL.md but no folder found at <SKILLS_ROOT>/<skill-name>/
    B. Remove from registry (delete decision tree line, Quick Ref row, Lifecycle entry)
    C. Keep ⚠️ marker as-is for now — I'll handle it manually

    Reply A / B / C:
```

**Wait for the user's answer before proceeding.**
- Answer **A** → run the `mv` command, then proceed to Step 4 treating the skill as present.
- Answer **B** → remove the skill from registry in Step 4.
    A. mv <found-path> → <SKILLS_ROOT>/<skill-name>/   (install it)

If multiple stale skills exist, ask about each one **individually** before making any edits.

### Step 4: Update using-agent-skills/SKILL.md

Apply changes with actual file edits (not descriptions of edits):

**For each Missing skill:**

1. Insert into the **decision tree** under the most semantically appropriate branch.
   If placement is ambiguous, add at the bottom with a comment:
   ```
   └── [skill purpose]? ──→ new-skill-name
   ```
2. Insert into the **Quick Reference** table with the correct Phase column:
   ```
   | Phase | new-skill-name | Description one-liner |
   ```
3. If the skill fits naturally into the **Lifecycle Sequence**, insert it at the right position.

**For each Stale skill:**
- Action determined by user answer in Step 3a (mv / remove / annotate). Do not auto-remove.

**For Description drift:**
- Update only the Quick Ref table cell — don't rewrite the decision tree label.

- Answer **C** → ensure the `⚠️ not in <SKILLS_ROOT>/ yet` annotation is in the decision tree and Quick Ref row, then move on.

- [ ] Every directory under `<SKILLS_ROOT>/` appears exactly once in Quick Ref

### Step 6: Self-Check

### Step 5: Check Other Index Files

Scan for files that enumerate skills — detect OS, then run the matching block:

- **Windows** →
  ```powershell
  Get-ChildItem '<project-root>' -Recurse -Include '*.md','*.json','*.yml' |
    Select-String -Pattern 'using-agent-skills|skill.*SKILL\.md|\.github/skills' |
    Select-Object -ExpandProperty Path | Sort-Object -Unique
  ```
- **Linux / Mac** →
  ```bash
  grep -rl "using-agent-skills\|skill.*SKILL\.md\|\.github/skills" <project-root> \
    --include="*.md" --include="*.json" --include="*.yml"
  ```
- [ ] No skill name appears in the decision tree that doesn't have a folder on disk
- [ ] Quick Ref descriptions match the first sentence of each SKILL.md's `description:` frontmatter
- [ ] Phase assignments in Quick Ref are accurate (Define / Plan / Build / Verify / Review / Ship / Maintain)

### Step 7: Summary

Report concisely:

```
## Skill Sync Complete

**Added** (N):
- skill-name — placed under [Branch] in decision tree, Phase: [X]

**Removed** (N):
- skill-name — no longer found on disk

**Updated** (N):
- skill-name — description refreshed

**No change** (N): [list skill names]
```

If nothing changed, just say: "Skills registry already in sync (N skills). No changes made."

---

## Phase Reference

Use this to assign skills to the correct Quick Ref phase:

| Phase | Typical skills |
|-------|---------------|
| **Define** | idea-refine, spec-driven-development |
| **Plan** | planning-and-task-breakdown |
| **Build** | incremental-implementation, frontend-ui-engineering, api-and-interface-design, context-engineering, source-driven-development |
| **Verify** | test-driven-development, browser-testing-with-devtools, debugging-and-error-recovery |
| **Review** | code-review-and-quality, code-simplification, security-and-hardening, performance-optimization |
| **Ship** | git-workflow-and-versioning, ci-cd-and-automation, documentation-and-adrs, shipping-and-launch, deprecation-and-migration |
| **Maintain** | neat-freak, skill-sync, using-agent-skills |

When a new skill's phase is unclear, read the first 20 lines of its SKILL.md and infer from context.

---

## What This Skill Does NOT Do

- Does not modify any skill's own `SKILL.md` content
- Does not touch project docs (`README.md`, `CLAUDE.md`, `docs/`)
- Does not update agent memory
- Does not rename or move skill folders
- Does not create new skills

For project-wide doc sync → use **neat-freak**.
For creating a new skill → write the `SKILL.md` manually, then run `skill-sync` to register it.
