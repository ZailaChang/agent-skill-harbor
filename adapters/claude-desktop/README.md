# Claude Desktop Adapter

Installs agent-skill-harbor skills for Anthropic Claude Desktop.

## Status

⚠️ **Placeholder** - Not yet implemented

## Planned Runtime Paths

| OS | Path |
|----|------|
| macOS | `~/Library/Application Support/Claude/skills/` |
| Linux | `~/.config/Claude/skills/` |
| Windows | `%APPDATA%\Claude\skills\` |

## Planned Format

Skills will be converted to either:
1. **MCP Server format** - For programmatic access
2. **Markdown in system prompt** - For direct injection

## Future Work

- Detect Claude Desktop installation
- Implement format converter
- Create installation scripts
- Test with Claude API

## Contributing

If you use Claude Desktop and want to help implement this adapter, please open an issue or PR!
