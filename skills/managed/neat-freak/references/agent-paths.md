# Agent Memory & Config Path Reference

Different agent platforms store memory and project config in different locations. Use this table during Step 1 to find the right paths for whichever platform you are running on.

## Claude Code

| Purpose | Path |
|---|---|
| Cross-session memory (global) | `~/.claude/projects/<encoded-project-path>/memory/` |
| Memory index file | `~/.claude/projects/<...>/memory/MEMORY.md` |
| Global instructions | `~/.claude/CLAUDE.md` |
| Project-level instructions | Project-root `CLAUDE.md` (nestable per directory) |
| Skills directory | `~/.claude/skills/<name>/SKILL.md` |

Memory files use YAML frontmatter with keys: `name`, `description`, `type` (`user` / `feedback` / `project` / `reference`).

## OpenAI Codex

| Purpose | Path |
|---|---|
| Cross-session instructions (global) | `~/.codex/AGENTS.md` or `$CODEX_HOME/AGENTS.md` |
| Project-level instructions | Project-root `AGENTS.md` (nestable per directory) |
| Project-level override | `AGENTS.override.md` (if present, overrides `AGENTS.md` in the same directory) |
| Skills directory | `~/.codex/skills/<name>/SKILL.md` or project-local `.codex/skills/<name>/` |

Codex has no separate "memory files + index" mechanism. All cross-session information goes directly into `AGENTS.md`. During sync, consolidate "project facts" into that file.

Also check for `TEAM_GUIDE.md` or `.agents.md` in the project — these are Codex fallback filenames.

## OpenClaw

| Purpose | Path |
|---|---|
| User-level skills | `~/.openclaw/skills/<name>/SKILL.md` (auto-created on first run) |
| Project-level skills | `.openclaw/skills/<name>/SKILL.md` (under repo root) |
| Workspace skills | `skills/` directory of the current workspace |

**Load priority**: workspace > project-agent > personal-agent > managed/local > bundled > extra dirs. A higher-priority skill with the same name overrides lower-priority ones.

OpenClaw has no separate memory system. Cross-session information can be placed in a project-root markdown file (CLAUDE.md / AGENTS.md / equivalent), following the Codex pattern. Frontmatter supports a `metadata.openclaw` field for load-time gating (by OS, env var, binary dependency), but this is not required for neat-freak.

## OpenCode

| Purpose | Path |
|---|---|
| Global config | `~/.config/opencode/` |
| Project config | `.opencode/` |
| Skills directory (project) | `.opencode/skills/`, `.claude/skills/`, `.codex/skills/` — all are scanned |
| Skills directory (global) | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/` |

OpenCode reads both Claude Code and Codex directories, so a skill installed under `~/.claude/skills/` is recognized by all three. OpenClaw uses its own `~/.openclaw/skills/` and requires a separate install (or a symlink).

## If the Current Agent Has No Dedicated Memory System

Skip the memory layer entirely and focus all effort on:
- Project-root markdown (`CLAUDE.md` / `AGENTS.md` / platform equivalent)
- `README.md`
- `docs/`

This is still a valid and valuable sync — memory is a bonus on top; docs are the minimum guarantee of project knowledge.

## Co-existence Strategy (Multiple Platforms on One Project)

If a project is used by both Claude Code and Codex users:

- **Put both `CLAUDE.md` and `AGENTS.md` in the project root** — content can be symlinked or maintained in both files
- Or keep one canonical file and have the other contain a single line: `See CLAUDE.md`
- `docs/` and `README.md` are platform-neutral — no duplication needed
