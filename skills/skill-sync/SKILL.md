---
name: skill-sync
description: >
  Dynamically reconciles the skills registry (using-agent-skills/SKILL.md) against
  the actual skill directories on disk — adds missing entries, removes stale ones,
  and updates descriptions. Scope is SKILLS ONLY, not the whole project.
  MUST trigger when the user says: "整理 skills", "sync skills", "列出 skills",
  "update skills list", "新 skill 加進去", "skills 清單", "/skills", "/skill-sync",
  "skill 對齊", "哪些 skills", "skills 有哪些", or any phrase asking to list,
  audit, or align the skills registry without a full project sync.
---

# Skill Sync — Skills Registry Aligner

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

```
ls <skills-root>/          # e.g., .github/skills/ or agent-skills/skills/
```

For each subdirectory, read its `SKILL.md` frontmatter:
- `name:` — canonical identifier
- `description:` — one-liner for the quick-reference table

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
| **Stale** | In declared registry, not on disk at `<skills-root>/` | **STOP — ask user (see Step 3a)** |
| **Description drift** | Description differs meaningfully | Update Quick Ref one-liner |

If diff is empty → report "already in sync, no changes needed" and stop.

#### Step 3a: Interactive Resolution for Stale Skills

For **each** stale skill found, before touching any file, present this prompt to the user:

```
⚠️  Stale skill detected: `<skill-name>`
    Declared in using-agent-skills/SKILL.md but no folder found at <skills-root>/<skill-name>/

    I also checked known staging areas and found:
    → <path-if-found-elsewhere>  (or "not found anywhere")

    What should I do?
    A. mv <found-path> → <skills-root>/<skill-name>/   (install it)
    B. Remove from registry (delete decision tree line, Quick Ref row, Lifecycle entry)
    C. Keep ⚠️ marker as-is for now — I'll handle it manually

    Reply A / B / C:
```

**Wait for the user's answer before proceeding.**
- Answer **A** → run the `mv` command, then proceed to Step 4 treating the skill as present.
- Answer **B** → remove the skill from registry in Step 4.
- Answer **C** → ensure the `⚠️ not in <skills-root>/ yet` annotation is in the decision tree and Quick Ref row, then move on.

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

### Step 5: Check Other Index Files

Scan for files that enumerate skills:
```
grep -rl "using-agent-skills\|skill.*SKILL.md\|\.github/skills" <project-root> \
  --include="*.md" --include="*.json" --include="*.yml" -l
```

Common candidates: `copilot-instructions.md`, `CLAUDE.md`, `.vscode/settings.json` (if skills are listed there).

For each candidate: check if new/removed skills need to appear there too. Only update if the file explicitly lists individual skill names — don't touch files that just reference the skills folder path.

### Step 6: Self-Check

- [ ] Every directory under `<skills-root>/` appears exactly once in Quick Ref
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
