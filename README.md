# agent-skill-harbor

**A multi-agent skill system with project bootstrap, registry sync, and session cleanup.**

agent-skill-harbor provides a structured skill workflow for AI assistants — bringing new projects online in seconds, keeping skills aligned, and reconciling documentation at the end of every session.

**Multi-Agent:** Works with GitHub Copilot, Claude Desktop (coming soon), Cursor (coming soon), and any agent through generic markdown export.

```
  NEW PROJECT          ONGOING            END OF SESSION
 ┌───────────┐      ┌──────────┐        ┌────────────┐
 │  setup    │ ───▶ │   work   │  ───▶  │   /neat    │
 │  skills   │      │ + /skills│        │  sync up   │
 └───────────┘      └──────────┘        └────────────┘
  /bootstrap          /skills             neat-freak
```

---

## Architecture

```
agent-skill-harbor/
├── skills/                        ← Skill definitions (two tiers)
│   ├── managed/                   ← Controlled: vendor-neutral format
│   │   ├── neat-freak/
│   │   │   ├── skill.yaml        ← Metadata (triggers, agents, dependencies)
│   │   │   ├── content.md        ← Agent-agnostic instructions
│   │   │   └── references/       ← Supporting docs
│   │   ├── project-bootstrap/
│   │   └── skill-sync/
│   │
│   ├── external/                  ← Zero assumptions: any format
│   │   ├── example-skill/        ← Flat: just needs SKILL.md
│   │
│   └── registry/                  ← Optional tracking
│       └── index.yaml            ← Documents all skills
│
├── adapters/                      ← Agent-specific installers
│   ├── vscode-copilot/           ← GitHub Copilot in VS Code
│   │   ├── install.ps1           ← Windows installer
│   │   ├── install.sh            ← Linux/macOS installer
│   │   ├── format.py             ← Converts skill.yaml + content.md → SKILL.md
│   │   └── README.md
│   ├── claude-desktop/           ← Placeholder
│   ├── cursor/                   ← Placeholder
│   └── generic/                  ← Markdown export
│
├── setup.ps1                      ← Detects agent + delegates
├── setup.sh
└── docs/                          ← Architecture docs
    ├── skill-schema.yaml          ← skill.yaml format spec
    └── adapter-spec.md            ← Adapter requirements
```

**Two-Tier Design:**
- **managed/** - Strict format (skill.yaml + content.md), converted during installation
- **external/** - Lenient (just needs SKILL.md), copied as-is, supports nested repos

---

## Skills

| Skill | Trigger | What it does |
|-------|---------|-------------|
| [project-bootstrap](skills/project-bootstrap/SKILL.md) | `setup skills` / `/bootstrap` | Analyzes project docs → recommends skills (Mode A), or lets you pick from the full list (Mode B). Copies skills into `.github/skills/` and creates `.github/copilot-instructions.md`. |
| [skill-sync](skills/skill-sync/SKILL.md) | `sync skills` / `/skills` | Diffs skills on disk vs `using-agent-skills/SKILL.md` registry. Adds missing, asks about stale (mv / remove / keep), updates descriptions. |
| [neat-freak](skills/neat-freak/SKILL.md) | `整理一下` / `/neat` / `sync up` | End-of-session: reconciles project docs, CLAUDE.md, and agent memory against the code. Detects stale facts, relative dates, and cross-project drift. |

---

## Quick Start

**Auto-detect your AI assistant:**

```bash
# Linux/macOS
git clone https://github.com/ZailaChang/agent-skill-harbor.git /tmp/agent-skill-harbor
cd /tmp/agent-skill-harbor
bash setup.sh install

# Windows
git clone https://github.com/ZailaChang/agent-skill-harbor.git $env:TEMP\agent-skill-harbor
cd $env:TEMP\agent-skill-harbor
.\setup.ps1 install
```

The setup script detects your AI assistant (GitHub Copilot, Claude Desktop, Cursor) and installs skills in the correct format and location.

**Add external skills:**

```bash
# Clone any skill repo into external/
cd skills/external
git clone https://github.com/other-author/some-skills.git

# Reinstall to pick up new skills
cd ../..
bash setup.sh install  # Linux/macOS
# or
.\setup.ps1 install   # Windows
```

Supports both **flat** (SKILL.md at root) and **nested** (repo/skills/*/SKILL.md) structures.

**Installed locations:**
- **GitHub Copilot:** `~/.copilot/skills/` (Windows: `%USERPROFILE%\.copilot\skills\`)
- **Claude Desktop:** `~/Library/Application Support/Claude/skills/` (coming soon)
- **Cursor:** `~/.config/Cursor/skills/` (coming soon)

Reload your editor, then in any workspace:
```
setup skills
```

---

## Supported AI Assistants

| Assistant | Status | Adapter |
|-----------|--------|---------|
| **GitHub Copilot** (VS Code) | ✅ Stable | [vscode-copilot](adapters/vscode-copilot/) |
| Claude Desktop | 🚧 Planned | [claude-desktop](adapters/claude-desktop/) |
| Cursor IDE | 🚧 Planned | [cursor](adapters/cursor/) |
| Generic (any agent) | 🚧 Planned | [generic](adapters/generic/) - Markdown export |

**Want to add support for another agent?** See [docs/adapter-spec.md](docs/adapter-spec.md) for how to create an adapter.

---

## For Developers (Contributing Skills)

If you're developing or modifying skills:

```bash
# Clone to your projects directory
git clone https://github.com/ZailaChang/agent-skill-harbor.git ~/projects/agent-skill-harbor
cd ~/projects/agent-skill-harbor

# Install in dev mode (creates symlink for live editing)
skills/                                 ← Vendor-neutral definitions
  ├── neat-freak/
  │   ├── skill.yaml                   ← Metadata
  │   └── content.md                   ← Instructions
  └── project-bootstrap/
        ↓
   [Adapter converts format]
        ↓
~/.copilot/skills/                     ← Runtime location (Copilot)
  ├── neat-freak/
  │   └── SKILL.md                     ← Converted format
  └── project-bootstrap/
        ↓
   "setup skills" → project-bootstrap copies selected skills
        ↓
<project>/.github/skills/              ← Project-local active skills
<project>/.github/copilot-instructions.md
```

**Skill Format:** Each skill has:
- `skill.yaml` - Metadata (name, triggers, agent support, dependencies)
- `content.md` - Agent-agnostic instructions
- `references/` - Supporting documentation (optional)

See [docs/skill-schema.yaml](docs/skill-schema.yaml) for the complete format specification.

**Adapters:** Convert vendor-neutral skills to agent-specific formats:
- **vscode-copilot**: Generates `SKILL.md` with YAML frontmatter
- **claude-desktop**: Will generate MCP server format (planned)
- **cursor**: Will integrate with `.cursorrules` (planned)
- **generic**: Exports plain markdown (planned)
```bash
# Auto-detect agent and update
bash setup.sh update     # Linux/macOS
.\setup.ps1 update       # Windows
```

Or from the installed location:
```bash
~/.copilot/skills/adapters/vscode-copilot/install.sh update
```

For dev mode, just git pull (changes are immediate via symlink).

---

## Setup Modes

| Mode | Command | What it does |
|------|---------|-------------|
| `install` | `bash setup.sh install` | Copy skills to runtime location (default) |
| `dev` | `bash setup.sh dev` | Symlink to repo for development |
| `update` | `bash setup.sh update` | Pull latest and reinstall (same mode) |
| `uninstall` | `bash setup.sh uninstall` | Remove from runtime location |

Force a specific agent:
```bash
bash setup.sh --agent vscode-copilot install
bash setup.sh --agent claude-desktop dev
```

---

## Runtime Paths

| Agent | OS | Path |
|-------|----|----|
| GitHub Copilot | Windows | `%USERPROFILE%\.copilot\skills\` |
| GitHub Copilot | Linux/macOS | `~/.copilot/skills/` |
| Claude Desktop | macOS | `~/Library/Application Support/Claude/skills/` |
| Claude Desktop | Linux | `~/.config/Claude/skills/` |
| Cursor | Windows | `%APPDATA%\Cursor\skills\` |
| Cursor | macOS | `~/Library/Application Support/Cursor/skills/` |
| Cursor | Linux | `~/.config/Cursor/skills/` |

---

Instructions for the AI agent...
```

**4. Test it:**
```bash
bash setup.sh dev      # Install in dev mode
# Test in your AI assistant
```

See [docs/skill-schema.yaml](docs/skill-schema.yaml) for full specification
<project>/.github/skills/            ← project-local active skills
<project>/.github/copilot-instructions.md  ← auto-generated, loads skill triggers
```

`setup.sh` / `setup.ps1` installs skills to the standard location and configures VS Code `settings.json` so Copilot knows to read `project-bootstrap/SKILL.md` when you say "setup skills" — even in brand-new workspaces with no `.github/` yet.

**Development vs. Production:**
- **Install mode** (default): Copies skills to standard location. Safe, stable, isolated from repo.
- **Dev mode**: Symlinks to git repo for testing changes. Requires `dev` flag when running setup.

See [docs/vscode-copilot-setup.md](docs/vscode-copilot-setup.md) for the full setup details.

---

## Updating

### For End Users

```bash
# Update to latest version (pulls and reinstalls)
~/.copilot/skills/setup.sh update    # Linux/macOS
%USERPROFILE%\.copilot\skills\setup.ps1 update  # Windows (PowerShell)
```

### For Developers

```bash
cd ~/projects/agent-skill-harbor
git pull
# Changes are immediately available (symlinked)
```

---

## Setup Modes

| Mode | Command | What it does |
|------|---------|-------------|
| `install` | `bash setup.sh install` | Copy to standard location (default, recommended for users) |
| `dev` | `bash setup.sh dev` | Symlink to repo for development/testing |
| `update` | `bash setup.sh update` | Pull latest from git and reinstall (same mode) |
| `uninstall` | `bash setup.sh uninstall` | Remove from runtime location (keeps repo intact) |

---

## Architecture

| Tier | Path | Role |
|------|------|------|
| **Runtime location** | `~/.copilot/skills/` (Linux/macOS)<br>`%USERPROFILE%\.copilot\skills\` (Windows) | Where VS Code Copilot reads skills from. |
| **Development (optional)** | `~/projects/agent-skill-harbor/` | Git repo for developers contributing skills. |
| **Project skills** | `<project>/.github/skills/` | Skills active for that project. Copied by `project-bootstrap`. |

Add a new skill to the global pool → run `sync skills` in any project to register it.
