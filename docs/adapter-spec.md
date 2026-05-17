# Adapter Specification

Adapters translate vendor-neutral skills into agent-specific formats and install them into the correct runtime locations.

## Directory Structure

```
adapters/
├── vscode-copilot/
│   ├── install.ps1           # Windows installer
│   ├── install.sh            # Linux/macOS installer
│   ├── format.py             # Converts skill.yaml + content.md → SKILL.md
│   └── README.md             # Adapter-specific docs
│
├── claude-desktop/
│   ├── install.sh            # Universal installer
│   ├── format.py             # Converts to MCP server or markdown
│   └── README.md
│
├── cursor/
│   ├── install.sh
│   ├── format.py
│   └── README.md
│
└── generic/
    ├── export.py             # Exports standalone markdown
    └── README.md
```

## Adapter Requirements

Each adapter MUST provide:

1. **Installation script** (`install.sh` or `install.ps1`)
   - Detects OS and environment
   - Copies/symlinks skills to runtime location
   - Configures agent settings
   - Supports modes: `install`, `dev`, `update`, `uninstall`

2. **Format converter** (`format.py` or similar)
   - Reads `skill.yaml` + `content.md`
   - Generates agent-specific format
   - Handles templating (e.g., `<SKILLS_ROOT>` replacement)

3. **Documentation** (`README.md`)
   - Explains agent-specific setup
   - Documents runtime paths
   - Lists known limitations

## Format Converter Interface

```python
def convert_skill(skill_dir: Path, output_dir: Path, mode: str = "install") -> None:
    """
    Convert a skill to agent-specific format.
    
    Args:
        skill_dir: Path to skill directory (contains skill.yaml + content.md)
        output_dir: Where to write converted files
        mode: "install" (copy) or "dev" (reference original)
    
    Raises:
        ValueError: If skill.yaml is invalid
        FileNotFoundError: If required files are missing
    """
```

## Standard Runtime Paths

| Agent | OS | Default Runtime Path |
|-------|----|--------------------|
| VS Code Copilot | Windows | `%USERPROFILE%\.copilot\skills\` |
| VS Code Copilot | Linux/macOS | `~/.copilot/skills/` |
| Claude Desktop | macOS | `~/Library/Application Support/Claude/skills/` |
| Claude Desktop | Linux | `~/.config/Claude/skills/` |
| Cursor | Windows | `%APPDATA%\Cursor\skills\` |
| Cursor | macOS | `~/Library/Application Support/Cursor/skills/` |
| Cursor | Linux | `~/.config/Cursor/skills/` |

## Installation Modes

### Install Mode (Default)
- Copies skills to runtime location
- Converts format on-the-fly
- Isolated from source repo
- Safe for end users

### Dev Mode
- Symlinks to source repo
- Enables live editing
- For skill developers only
- May require elevated permissions

### Update Mode
- Pulls latest from git (if in git repo)
- Re-runs install with same mode
- Preserves user customizations

### Uninstall Mode
- Removes from runtime location
- Backs up to `.removed.TIMESTAMP`
- Keeps source repo intact
- Agent settings remain (harmless)

## Agent Detection

The main `setup.sh`/`setup.ps1` should detect the agent by checking:

```bash
# VS Code + Copilot
if [[ -f "$HOME/.config/Code/User/settings.json" ]] && \
   grep -q "github.copilot" "$HOME/.config/Code/User/settings.json" 2>/dev/null; then
  AGENT="vscode-copilot"
fi

# Claude Desktop
if [[ -d "$HOME/Library/Application Support/Claude" ]]; then
  AGENT="claude-desktop"
fi

# Cursor
if [[ -d "$HOME/.cursor" ]] || [[ -d "$HOME/.config/Cursor" ]]; then
  AGENT="cursor"
fi
```

## Multi-Agent Support

Users can install for multiple agents:

```bash
bash setup.sh install --agent vscode-copilot
bash setup.sh install --agent claude-desktop
```

Or auto-detect all:

```bash
bash setup.sh install --auto-detect
```

## Version Tracking

Each installation creates `.version` file:

```
# agent-skill-harbor installation metadata
agent=vscode-copilot
mode=install
source=/path/to/source
timestamp=2026-05-17T12:00:00Z
```

This enables upgrade path and debugging.
