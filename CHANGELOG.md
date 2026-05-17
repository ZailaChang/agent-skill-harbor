# Changelog

All notable changes to agent-skill-harbor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-17

### Added
- **Two-tier skill architecture** - Skills now organized into `managed/` and `external/` subdirectories
  - `skills/managed/` - Vendor-neutral format (skill.yaml + content.md), strict validation, controlled quality
  - `skills/external/` - Any format (just needs SKILL.md), copied as-is, zero assumptions, lazy integration
- **Nested repo support** - External repos like `agent-skills/skills/*/SKILL.md` now auto-discovered
- **Skill registry** - Added `skills/registry/index.yaml` to track all skills
- **Format converter normalization** - `format.py` now handles both new format (skill.yaml + content.md) AND old format (SKILL.md only)

### Changed
- **Installation flow** - Now processes two tiers separately:
  - Managed skills: Converted from skill.yaml + content.md → SKILL.md
  - External skills: Copied as-is, supports both flat and nested repo structures
- **Setup preview** - Shows which skills will be installed, grouped by managed vs external
- **project-bootstrap skill** - Updated to document two-tier discovery and nested repo search logic

### Example
Cloning external skills is now trivial:
```bash
cd skills/external
git clone https://github.com/addyosmani/agent-skills.git
cd ../..
./setup.ps1 install  # Automatically discovers skills in agent-skills/skills/
```

Total skills after this: **27** (3 managed + 24 external)

---

## [1.0.0] - 2026-05-17

### Major Release: Multi-Agent Architecture

This release introduces a complete architectural refactor to support multiple AI assistants.

### Added
- **Multi-agent support** - Skills now work with multiple AI assistants (Copilot, Claude Desktop, Cursor)
- **Vendor-neutral skill format** - New `skill.yaml` + `content.md` format
- **Adapter system** - Agent-specific converters and installers
  - `adapters/vscode-copilot/` - GitHub Copilot adapter (stable)
  - `adapters/claude-desktop/` - Claude Desktop adapter (placeholder)
  - `adapters/cursor/` - Cursor IDE adapter (placeholder)
  - `adapters/generic/` - Generic markdown export (placeholder)
- **Automatic agent detection** - Setup scripts detect your AI assistant
- **Format converter** (`format.py`) - Converts skill.yaml + content.md → SKILL.md
- **Comprehensive documentation**:
  - `docs/skill-schema.yaml` - Skill format specification
  - `docs/adapter-spec.md` - Adapter requirements and interface
  - `docs/MIGRATION.md` - Upgrade guide from v0.x

### Changed
- **Setup scripts refactored** - Now detect agent and delegate to adapters
  - `setup.ps1` / `setup.sh` are now orchestrators
  - Agent-specific logic moved to `adapters/*/install.*`
- **All core skills migrated** - All skills now use `skill.yaml` + `content.md` format
  - `neat-freak`, `project-bootstrap`, `skill-sync` converted
  - Old `SKILL.md` files retained for reference but not used
- **Installation flow** - Skills are converted during installation
  - `install` mode: Converts and copies to runtime location
  - `dev` mode: Symlinks source repo for live editing

### Refactored
- Moved `setup.ps1` → `adapters/vscode-copilot/install.ps1`
- Moved `setup.sh` → `adapters/vscode-copilot/install.sh`
- **All core skills converted to new format:**
  - `neat-freak`: `skill.yaml` + `content.md` ✅
  - `project-bootstrap`: `skill.yaml` + `content.md` ✅
  - `skill-sync`: `skill.yaml` + `content.md` ✅

### Migration
- **End users:** Run `bash setup.sh update` to upgrade
- **Skill developers:** See `docs/MIGRATION.md` for conversion guide
- **No breaking changes** for existing installations

---

## [0.9.0] - 2026-05-17

### Added
- Standard installation location (`~/.copilot/skills/`)
- Development vs production modes (`install` vs `dev`)
- Version tracking (`.version` file)
- `update` and `uninstall` commands
- UTF-8 without BOM encoding (fixes Windows BOM issues)

### Changed
- Installation path now consistent across all users
- Setup scripts enhanced with mode support

---

## [0.1.0] - 2026-04-XX

### Added
- Initial release
- Three core skills: `project-bootstrap`, `skill-sync`, `neat-freak`
- VS Code Copilot integration
- Setup scripts for Windows and Linux/macOS

---

## Roadmap

### [1.1.0] - Planned
- [ ] Claude Desktop adapter implementation
- [ ] Cursor adapter implementation
- [ ] Generic markdown exporter
- [ ] Convert all core skills to new format
- [ ] Skill dependency resolution

### [1.2.0] - Planned
- [ ] Web-based skill browser
- [ ] Skill marketplace integration
- [ ] Automatic skill updates

### [2.0.0] - Future
- [ ] MCP (Model Context Protocol) integration
- [ ] Cross-agent skill sharing
- [ ] Cloud-based skill sync
