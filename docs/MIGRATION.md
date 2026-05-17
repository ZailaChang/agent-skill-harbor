# Migration Guide: v0.x → v1.0

## What Changed

**v1.0 introduces multi-agent support** with a new architecture:

### Before (v0.x)
```
agent-skill-harbor/
├── skills/
│   └── neat-freak/
│       └── SKILL.md        ← Copilot-specific format
├── setup.ps1              ← Copilot-only installer
└── setup.sh
```

### After (v1.0)
```
agent-skill-harbor/
├── skills/
│   └── neat-freak/
│       ├── skill.yaml     ← Vendor-neutral metadata
│       └── content.md     ← Vendor-neutral instructions
├── adapters/
│   └── vscode-copilot/
│       ├── install.ps1    ← Copilot-specific installer
│       ├── install.sh
│       └── format.py      ← Converts to SKILL.md
├── setup.ps1              ← Agent detector (delegates to adapter)
└── setup.sh
```

**Skills are now defined once and work with multiple agents** (Copilot, Claude Desktop, Cursor, etc.)

---

## For End Users

### If you installed from the old version

**Nothing breaks immediately.** Your existing installation at `~/.copilot/skills/` still works.

To upgrade:

```bash
# Backup your current installation (optional)
cp -r ~/.copilot/skills ~/.copilot/skills.backup.v0

# Pull latest
cd /path/to/your/clone/agent-skill-harbor
git pull

# Reinstall with new setup
bash setup.sh update
```

The new setup will:
1. Detect you're using GitHub Copilot
2. Convert skills from `skill.yaml` + `content.md` to `SKILL.md` format
3. Install to the same location (`~/.copilot/skills/`)

**No changes needed in your projects.** Project-local skills (`.github/skills/`) remain unchanged.

### If you're installing fresh

Just follow the new Quick Start in README.md. The setup auto-detects your agent.

---

## For Skill Developers

### Converting Your Custom Skills

If you created custom skills in the old format, convert them to the new format:

**1. Create `skill.yaml`:**

Extract the YAML frontmatter from `SKILL.md` and expand it:

```yaml
# Old SKILL.md frontmatter:
---
name: my-skill
description: Does something
---

# New skill.yaml:
name: my-skill
version: 1.0.0
description: Does something

triggers:
  natural:
    - my trigger phrase
  command:
    - /myskill

agents:
  vscode-copilot:
    enabled: true
    target: .github/skills/
    config_file: .github/copilot-instructions.md
```

**2. Create `content.md`:**

Move everything after the frontmatter in `SKILL.md` to `content.md`:

```bash
# Extract content (skip frontmatter)
tail -n +5 skills/my-skill/SKILL.md > skills/my-skill/content.md
```

**3. Remove old SKILL.md:**

```bash
rm skills/my-skill/SKILL.md
```

**4. Test:**

```bash
bash setup.sh dev
# Check that your skill works
```

The adapter will convert `skill.yaml` + `content.md` back to `SKILL.md` format during installation.

### Why This Change?

- **Multi-agent support:** Define skills once, work with Copilot, Claude, Cursor, etc.
- **Cleaner separation:** Metadata in YAML, instructions in Markdown
- **Future-proof:** Add new agents without touching skills
- **Better tooling:** Adapters can validate, transform, and optimize per-agent

---

## Breaking Changes

### None for end users
- Existing installations continue to work
- Project-local skills (`.github/skills/`) unchanged
- Same triggers and commands

### For contributors
- Must use new `skill.yaml` + `content.md` format
- Old `SKILL.md` files are not processed by default (but can be kept for reference)
- Adapter pattern required for new agents

---

## Rollback

If you need to rollback to v0.x:

```bash
cd /path/to/your/clone/agent-skill-harbor
git checkout v0.9  # or your last known good commit
bash setup.sh update
```

Your backup at `~/.copilot/skills.backup.v0` remains untouched.

---

## Questions?

Open an issue: https://github.com/ZailaChang/agent-skill-harbor/issues
