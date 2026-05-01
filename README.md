# agent-skill-harbor

**A VS Code Copilot skill system with project bootstrap, registry sync, and session cleanup.**

agent-skill-harbor gives GitHub Copilot a structured skill workflow — bringing new projects online in seconds, keeping the skills registry aligned as you add skills, and reconciling docs at the end of every session.

```
  NEW PROJECT          ONGOING            END OF SESSION
 ┌───────────┐      ┌──────────┐        ┌────────────┐
 │  setup    │ ───▶ │   work   │  ───▶  │   /neat    │
 │  skills   │      │ + /skills│        │  sync up   │
 └───────────┘      └──────────┘        └────────────┘
  /bootstrap          /skills             neat-freak
```

---

## Skills

| Skill | Trigger | What it does |
|-------|---------|-------------|
| [project-bootstrap](skills/project-bootstrap/SKILL.md) | `setup skills` / `/bootstrap` | Analyzes project docs → recommends skills (Mode A), or lets you pick from the full list (Mode B). Copies skills into `.github/skills/` and creates `.github/copilot-instructions.md`. |
| [skill-sync](skills/skill-sync/SKILL.md) | `sync skills` / `/skills` | Diffs skills on disk vs `using-agent-skills/SKILL.md` registry. Adds missing, asks about stale (mv / remove / keep), updates descriptions. |
| [neat-freak](skills/neat-freak/SKILL.md) | `整理一下` / `/neat` / `sync up` | End-of-session: reconciles project docs, CLAUDE.md, and agent memory against the code. Detects stale facts, relative dates, and cross-project drift. |

---

## Quick Start

### Linux / macOS / SSH Remote

```bash
git clone https://github.com/ZailaChang/agent-skill-harbor.git ~/workspaceAI/agent-skill-harbor
bash ~/workspaceAI/agent-skill-harbor/setup.sh
```

Reload VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`), then in any workspace:

```
setup skills
```

### Windows (local VS Code)

```powershell
git clone https://github.com/ZailaChang/agent-skill-harbor.git C:\Users\<you>\workspaceAI\agent-skill-harbor
cd C:\Users\<you>\workspaceAI\agent-skill-harbor
.\setup.ps1
```

Then reload VS Code and say `setup skills`.

---

## How It Works

```
~/workspaceAI/agent-skill-harbor/skills/   ← global pool (this repo)
         │
         │  "setup skills" → project-bootstrap copies selected skills
         ▼
<project>/.github/skills/            ← project-local active skills
<project>/.github/copilot-instructions.md  ← auto-generated, loads skill triggers
```

`setup.sh` / `setup.ps1` writes VS Code user `settings.json` so Copilot knows to read `project-bootstrap/SKILL.md` when you say "setup skills" — even in brand-new workspaces with no `.github/` yet.

See [docs/vscode-copilot-setup.md](docs/vscode-copilot-setup.md) for the full setup details.

---

## Updating

```bash
cd ~/workspaceAI/agent-skill-harbor && git pull
# No re-setup needed — paths don't change
```

---

## Two-Tier Architecture

| Tier | Path | Role |
|------|------|------|
| **Global pool** | `~/workspaceAI/agent-skill-harbor/skills/` | All available skills. Safe to `git pull`. |
| **Project skills** | `<project>/.github/skills/` | Skills active for that project. Copied by `project-bootstrap`. |

Add a new skill to the global pool → run `sync skills` in any project to register it.
