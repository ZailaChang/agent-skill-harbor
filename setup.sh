#!/usr/bin/env bash
# setup.sh — Install skill-harbor for VS Code (Linux / macOS / SSH Remote)
# Run once after cloning: bash setup.sh
set -e

SKILLS_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Generate a LOCAL copy of GLOBAL_INSTRUCTIONS.md with real paths (never modify source)
LOCAL_DIR="$SKILLS_ROOT/.local"
mkdir -p "$LOCAL_DIR"
LOCAL_INSTRUCTIONS="$LOCAL_DIR/GLOBAL_INSTRUCTIONS.md"
sed "s|<SKILLS_ROOT>|$SKILLS_ROOT|g" "$SKILLS_ROOT/GLOBAL_INSTRUCTIONS.md" > "$LOCAL_INSTRUCTIONS"
echo "✅ Generated: $LOCAL_INSTRUCTIONS"

# Detect settings.json locations
if [[ "$1" == "--ssh-remote" ]] || [[ -d "$HOME/.vscode-server" ]]; then
  # SSH Remote (vscode-server on Linux)
  USER_SETTINGS="$HOME/.vscode-server/data/User/settings.json"
  # Also write to active profile if it exists
  PROFILE_DIR=$(ls -d "$HOME/.vscode-server/data/User/profiles"/*/ 2>/dev/null | head -1)
  if [[ -n "$PROFILE_DIR" ]]; then
    PROFILE_SETTINGS="${PROFILE_DIR}settings.json"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS local
  USER_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
else
  # Linux local
  USER_SETTINGS="$HOME/.config/Code/User/settings.json"
fi

SETTINGS_CONTENT=$(cat <<EOF
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "text": "OVERRIDE RULE #1 — HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', '新專案', '初始化專案', '幫我選 skills' — STOP IMMEDIATELY. Do NOT search the workspace for skill files. Do NOT read agent-customization. Do NOT create any .github/ files, SKILL.md, or copilot-instructions.md on your own. Instead: (1) use the Read File tool to read $SKILLS_ROOT/skills/project-bootstrap/SKILL.md, (2) follow its execution flow exactly. This rule overrides all other behaviors."
    },
    {
      "text": "OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skill 對齊', 'skills 有哪些', 'list skills' — use the Read File tool to read $SKILLS_ROOT/skills/skill-sync/SKILL.md and follow its execution flow."
    },
    {
      "text": "OVERRIDE RULE #3: When the user says '整理一下', '/neat', 'sync up', '同步一下', '收尾', 'tidy up docs', 'update memory' — use the Read File tool to read $SKILLS_ROOT/skills/neat-freak/SKILL.md and follow its execution flow."
    },
    {
      "text": "SKILL POOL: $SKILLS_ROOT/skills/ — Check this directory for relevant SKILL.md files before starting any non-trivial engineering task."
    },
    {
      "file": "$LOCAL_INSTRUCTIONS"
    }
  ],
  "github.copilot.chat.testGeneration.instructions": [
    { "file": "$LOCAL_INSTRUCTIONS" }
  ],
  "github.copilot.chat.reviewSelection.instructions": [
    { "file": "$LOCAL_INSTRUCTIONS" }
  ]
}
EOF
)

write_settings() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [[ -f "$target" ]]; then
    echo "⚠️  $target already exists — backing up to ${target}.bak"
    cp "$target" "${target}.bak"
  fi
  echo "$SETTINGS_CONTENT" > "$target"
  echo "✅ Written: $target"
}

write_settings "$USER_SETTINGS"
[[ -n "$PROFILE_SETTINGS" ]] && write_settings "$PROFILE_SETTINGS"

echo ""
echo "✅ Done. Reload VS Code window: Ctrl+Shift+P → Developer: Reload Window"
echo "   Skills root: $SKILLS_ROOT"
