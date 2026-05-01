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
  USER_SETTINGS="$HOME/.vscode-server/data/User/settings.json"
  PROFILES_DIR="$HOME/.vscode-server/data/User/profiles"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  USER_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
  PROFILES_DIR="$HOME/Library/Application Support/Code/User/profiles"
else
  USER_SETTINGS="$HOME/.config/Code/User/settings.json"
  PROFILES_DIR="$HOME/.config/Code/User/profiles"
fi

# Collect all profiles that already have a settings.json
PROFILE_SETTINGS=()
if [[ -d "$PROFILES_DIR" ]]; then
  while IFS= read -r -d '' p; do
    PROFILE_SETTINGS+=("$p")
  done < <(find "$PROFILES_DIR" -maxdepth 2 -name "settings.json" -print0 2>/dev/null | sort -z)
fi

# merge_settings: read existing JSON, inject only Copilot keys, write back (requires python3)
merge_settings() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [[ -f "$target" ]]; then
    echo "⚠️  $target already exists — backing up to ${target}.bak"
    cp "$target" "${target}.bak"
  fi
  python3 - "$target" "$LOCAL_INSTRUCTIONS" "$SKILLS_ROOT" <<'PYEOF'
import sys, json, os
target, local_instructions, skills_root = sys.argv[1], sys.argv[2], sys.argv[3]
if os.path.exists(target) and os.path.getsize(target) > 0:
    try:
        settings = json.load(open(target))
    except Exception:
        settings = {}
else:
    settings = {}
settings["github.copilot.chat.codeGeneration.instructions"] = [
    {"text": f"OVERRIDE RULE #1 — HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', '新專案', '初始化專案', '幫我選 skills' — STOP IMMEDIATELY. Do NOT search the workspace for skill files. Do NOT read agent-customization. Do NOT create any .github/ files, SKILL.md, or copilot-instructions.md on your own. Instead: (1) recursively search {skills_root}/skills/ for project-bootstrap/SKILL.md, (2) read it using the Read File tool, (3) follow its execution flow exactly. This rule overrides all other behaviors."},
    {"text": f"OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skill 對齊', 'skills 有哪些', 'list skills' — recursively search {skills_root}/skills/ for skill-sync/SKILL.md, read it, and follow its execution flow."},
    {"text": f"OVERRIDE RULE #3: When the user says '整理一下', '/neat', 'sync up', '同步一下', '收尾', 'tidy up docs', 'update memory' — recursively search {skills_root}/skills/ for neat-freak/SKILL.md, read it, and follow its execution flow."},
    {"text": f"SKILL POOL: {skills_root}/skills/ — Recursively search this directory and all subdirectories for SKILL.md files before starting any non-trivial engineering task. Skills may be organized in flat or nested structures (e.g., skills/<name>/SKILL.md or skills/repo/skills/<name>/SKILL.md)."},
    {"file": local_instructions},
]
settings["github.copilot.chat.testGeneration.instructions"] = [{"file": local_instructions}]
settings["github.copilot.chat.reviewSelection.instructions"] = [{"file": local_instructions}]
with open(target, 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')
PYEOF
  echo "✅ Written: $target"
}

merge_settings "$USER_SETTINGS"

# Profile picker — show numbered list, let user pick one or all
if [[ ${#PROFILE_SETTINGS[@]} -gt 0 ]]; then
  echo ""
  echo "Found ${#PROFILE_SETTINGS[@]} profile(s) with settings:"
  for i in "${!PROFILE_SETTINGS[@]}"; do
    echo "  [$((i+1))] ${PROFILE_SETTINGS[$i]}"
  done
  echo "  [A] All profiles"
  echo "  [Enter] Skip"
  read -rp "Merge into which profile? " choice
  if [[ "$choice" =~ ^[Aa]$ ]]; then
    for p in "${PROFILE_SETTINGS[@]}"; do merge_settings "$p"; done
  elif [[ "$choice" =~ ^[0-9]+$ ]]; then
    idx=$((choice - 1))
    if [[ $idx -ge 0 && $idx -lt ${#PROFILE_SETTINGS[@]} ]]; then
      merge_settings "${PROFILE_SETTINGS[$idx]}"
    else
      echo "Invalid number — skipping profiles."
    fi
  else
    echo "Skipping profiles."
  fi
fi

echo ""
echo "✅ Done. Reload VS Code window: Ctrl+Shift+P → Developer: Reload Window"
echo "   Skills root: $SKILLS_ROOT"
