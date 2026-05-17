# Global Agent Instructions

> These are MANDATORY rules. Follow them exactly. Do not improvise.
>
> **Standard installation location (all users):**
> - Windows: `%USERPROFILE%\.copilot\skills\`
> - Linux/macOS: `~/.copilot/skills/`
>
> **After cloning this repo:** Run `bash setup.sh install` (Linux/macOS) or `.\setup.ps1 install` (Windows).
> The setup script copies/symlinks skills to the standard location and configures VS Code to use them.

## Skill Pool Location

All agent skills are stored under:
```
<SKILLS_ROOT>/skills/
```

**Two-Tier Structure:**
- `<SKILLS_ROOT>/skills/managed/` - Vendor-neutral format (skill.yaml + content.md), strict validation
- `<SKILLS_ROOT>/skills/external/` - Any format (just needs SKILL.md), copied as-is, zero assumptions

**Note:** `<SKILLS_ROOT>` is a placeholder replaced by the setup script with the actual runtime path.
For end users, this will be the standard location (`~/.copilot/skills/` or `%USERPROFILE%\.copilot\skills\`).
For developers using `dev` mode, this points to the git repository via symlink.

Skills may be organized in **flat or nested structures**:
- `<SKILLS_ROOT>/skills/managed/<skill-name>/` (managed skills)
- `<SKILLS_ROOT>/skills/external/<skill-name>/SKILL.md` (flat external)
- `<SKILLS_ROOT>/skills/external/<repo>/skills/<skill-name>/SKILL.md` (nested repo)

Always **search recursively** to find skills. This is the **global staging pool**. 
Skills are promoted to `.github/skills/` inside a project to become active for that project.

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

Before starting any non-trivial engineering task, recursively search for relevant skills:
```
find <SKILLS_ROOT>/skills/ -name "SKILL.md" -type f
# or PowerShell: Get-ChildItem -Path "<SKILLS_ROOT>/skills" -Recurse -Filter "SKILL.md"
```

**Core skills** (always present):
- **neat-freak** — End-of-session documentation and memory sync
- **project-bootstrap** — Import skills into new projects
- **skill-sync** — Keep project skills registry aligned

**Additional skills** may be added by users based on their workflow needs.
To discover available skills, recursively scan the skills directory.
