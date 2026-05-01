# Global Agent Instructions

> These are MANDATORY rules. Follow them exactly. Do not improvise.
>
> **After cloning this repo:** run `bash setup.sh` (Linux/macOS) or `.\setup.ps1` (Windows).
> The setup script replaces `<SKILLS_ROOT>` below with your actual clone path and generates
> `.local/GLOBAL_INSTRUCTIONS.md`, which VS Code references via `settings.json`.

## Skill Pool Location

All agent skills are stored at:
```
<SKILLS_ROOT>/skills/
```

This is the **global staging pool**. Skills are promoted to `.github/skills/` inside a
project to become active for that project.

## Project Bootstrap — MANDATORY — READ BEFORE DOING ANYTHING

When the user says ANY of the following (even approximately):
- "setup skills", "setup agent skills", "bootstrap", "/bootstrap", "/project-setup"
- "新專案", "初始化專案", "專案 setup", "幫我選 skills", "import skills"
- "which skills should I use", "what skills do I need"

**STOP. Do NOT:**
- Create any files
- Create copilot-instructions.md
- Create custom skill SKILL.md files
- Ask generic questions like "what kind of skills do you want?"
- Guess what skills the user needs based on the filesystem

**INSTEAD, you MUST:**
1. Read: `<SKILLS_ROOT>/skills/project-bootstrap/SKILL.md`
2. Follow its execution flow exactly (Mode A or Mode B as defined there).
3. Only after reading that file should you proceed.

## Skill Sync

When the user says: "sync skills", "整理 skills", "/skills", "/skill-sync", "skills 有哪些",
"skill 對齊", "list skills":

1. Read: `<SKILLS_ROOT>/skills/skill-sync/SKILL.md`
2. Follow its execution flow.

## End-of-Session Cleanup

When the user says: "整理一下", "sync up", "/neat", "同步一下", "收尾", "tidy up docs":

1. Read: `<SKILLS_ROOT>/skills/neat-freak/SKILL.md`
2. Follow its execution flow.

## General Rule

Before starting any non-trivial engineering task, check if a relevant skill exists at:
```
<SKILLS_ROOT>/skills/<skill-name>/SKILL.md
```

Available skills (check folder for latest list):
- api-and-interface-design, browser-testing-with-devtools, ci-cd-and-automation
- code-review-and-quality, code-simplification, context-engineering
- debugging-and-error-recovery, deprecation-and-migration, documentation-and-adrs
- frontend-ui-engineering, git-workflow-and-versioning, idea-refine
- incremental-implementation, neat-freak, performance-optimization
- planning-and-task-breakdown, project-bootstrap, security-and-hardening
- shipping-and-launch, skill-sync, source-driven-development
- spec-driven-development, test-driven-development, using-agent-skills
