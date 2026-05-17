# VS Code Copilot Adapter

Installs agent-skill-harbor skills for GitHub Copilot in VS Code.

## Runtime Paths

| OS | Path |
|----|------|
| Windows | `%USERPROFILE%\.copilot\skills\` |
| Linux/macOS | `~/.copilot/skills/` |

## Project Structure

Skills are copied to project-local directories:
```
<project>/.github/skills/
<project>/.github/copilot-instructions.md
```

## Installation

```powershell
# Windows
.\adapters\vscode-copilot\install.ps1 install

# Linux/macOS
bash adapters/vscode-copilot/install.sh install
```

## Modes

- `install` - Copy skills to runtime location (default)
- `dev` - Symlink to source repo for development
- `update` - Pull latest and reinstall
- `uninstall` - Remove from runtime location

## Format Conversion

The adapter converts vendor-neutral skills to Copilot's format:

**Input:**
- `skill.yaml` - Metadata
- `content.md` - Instructions

**Output:**
- `SKILL.md` - Combined format with YAML frontmatter

**Conversion:**
```python
python format.py <skill_dir> <output_dir>
```

## VS Code Settings

The installer modifies:
```
%APPDATA%\Code\User\settings.json
```

Keys modified:
- `github.copilot.chat.codeGeneration.instructions`
- `github.copilot.chat.testGeneration.instructions`
- `github.copilot.chat.reviewSelection.instructions`

## Requirements

- VS Code 1.80+
- GitHub Copilot extension
- PowerShell 5.1+ (Windows) or Bash 4.0+ (Linux/macOS)
- Python 3.8+ (for format converter)
