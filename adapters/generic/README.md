# Generic Adapter

Exports skills as standalone markdown files for any agent or manual use.

## Purpose

Provides a fallback format for:
- Agents not yet supported
- Manual copy-paste into prompts
- Documentation purposes
- Offline use

## Usage

```bash
python adapters/generic/export.py <output_dir>
```

This creates:
```
<output_dir>/
  project-bootstrap.md
  debugging.md
  neat-freak.md
  ...
```

Each file contains the full skill content with minimal formatting, ready to be copied into any AI assistant.

## Format

Plain markdown without agent-specific syntax:
- No YAML frontmatter
- No special triggers
- Human-readable headers
- Portable

## Future Work

- Implement export.py script
- Add PDF export option
- Add HTML export option
