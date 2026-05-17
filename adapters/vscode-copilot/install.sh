#!/usr/bin/env bash
# setup.sh — Install agent-skill-harbor for VS Code (Linux/macOS/SSH Remote)
#
# Usage:
#   bash setup.sh install   — Copy to standard location (default)
#   bash setup.sh dev       — Symlink to dev repo for testing
#   bash setup.sh update    — Pull latest and refresh runtime
#   bash setup.sh uninstall — Remove from runtime location
set -e

MODE="${1:-install}"
SOURCE_ROOT="$(cd "$(dirname "$0")" && pwd)"
STANDARD_LOCATION="$HOME/.copilot/skills"
VERSION_FILE="$STANDARD_LOCATION/.version"

# Detect VS Code settings locations
if [[ "$2" == "--ssh-remote" ]] || [[ -d "$HOME/.vscode-server" ]]; then
  USER_SETTINGS="$HOME/.vscode-server/data/User/settings.json"
  PROFILES_DIR="$HOME/.vscode-server/data/User/profiles"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  USER_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
  PROFILES_DIR="$HOME/Library/Application Support/Code/User/profiles"
else
  USER_SETTINGS="$HOME/.config/Code/User/settings.json"
  PROFILES_DIR="$HOME/.config/Code/User/profiles"
fi

# Helper functions
write_version_file() {
  local mode="$1" source="$2"
  cat > "$VERSION_FILE" <<EOF
# agent-skill-harbor installation metadata
mode=$mode
source=$source
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
}

install_skills() {
  local mode="$1"
  echo "Installing to: $STANDARD_LOCATION"
  
  if [[ "$mode" == "dev" ]]; then
    # Dev mode: create symlink
    if [[ -e "$STANDARD_LOCATION" ]]; then
      rm -rf "$STANDARD_LOCATION"
    fi
    
    ln -sf "$SOURCE_ROOT" "$STANDARD_LOCATION"
    echo "✅ Created symlink: $STANDARD_LOCATION → $SOURCE_ROOT"
    write_version_file "dev" "$SOURCE_ROOT"
  else
    # Install mode: copy files
    if [[ -e "$STANDARD_LOCATION" ]]; then
      echo "⚠️  Existing installation found - backing up..."
      backup_path="$STANDARD_LOCATION.bak.$(date +%Y%m%d-%H%M%S)"
      mv "$STANDARD_LOCATION" "$backup_path"
      echo "   Backed up to: $backup_path"
    fi
    
    cp -r "$SOURCE_ROOT" "$STANDARD_LOCATION"
    echo "✅ Copied to: $STANDARD_LOCATION"
    write_version_file "install" "$SOURCE_ROOT"
  fi
}

uninstall_skills() {
  if [[ ! -e "$STANDARD_LOCATION" ]]; then
    echo "No installation found at: $STANDARD_LOCATION"
    return
  fi
  
  backup_path="$STANDARD_LOCATION.removed.$(date +%Y%m%d-%H%M%S)"
  mv "$STANDARD_LOCATION" "$backup_path"
  echo "✅ Removed installation (backed up to: $backup_path)"
  echo "   VS Code settings retain the path but will not find skills."
}

update_skills() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "❌ No installation found. Run 'bash setup.sh install' first."
    exit 1
  fi
  
  # shellcheck disable=SC1090
  source "$VERSION_FILE"
  echo "Current mode: $mode"
  
  # Pull latest from git
  cd "$SOURCE_ROOT"
  echo "Pulling latest changes..."
  git pull
  cd - > /dev/null
  
  # Reinstall with same mode
  install_skills "$mode"
  echo "✅ Updated to latest version"
}

# Main execution
case "$MODE" in
  uninstall)
    uninstall_skills
    echo ""
    echo "Note: VS Code settings still reference $STANDARD_LOCATION"
    echo "      They are harmless and can be left in place."
    exit 0
    ;;
  update)
    update_skills
    # Continue to update VS Code settings
    ;;
  install|dev)
    install_skills "$MODE"
    # Continue to update VS Code settings
    ;;
  *)
    echo "Usage: bash setup.sh [install|dev|update|uninstall]"
    exit 1
    ;;
esac

# Generate GLOBAL_INSTRUCTIONS.md with standard path
LOCAL_DIR="$STANDARD_LOCATION/.local"
mkdir -p "$LOCAL_DIR"
LOCAL_INSTRUCTIONS="$LOCAL_DIR/GLOBAL_INSTRUCTIONS.md"
sed "s|<SKILLS_ROOT>|$STANDARD_LOCATION|g" "$SOURCE_ROOT/GLOBAL_INSTRUCTIONS.md" > "$LOCAL_INSTRUCTIONS"
echo "✅ Generated: $LOCAL_INSTRUCTIONS"

# Collect all profiles that already have a settings.json
PROFILE_SETTINGS=()
if [[ -d "$PROFILES_DIR" ]]; then
  while IFS= read -r -d '' p; do
    PROFILE_SETTINGS+=("$p")
  done < <(find "$PROFILES_DIR" -maxdepth 2 -name "settings.json" -print0 2>/dev/null | sort -z)
fi

# merge_settings: read existing JSON, inject only Copilot keys, write back
merge_settings() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  
  python3 - "$target" "$LOCAL_INSTRUCTIONS" "$STANDARD_LOCATION" <<'PYEOF'
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
    {"text": f"OVERRIDE RULE #1 - HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', or any phrase about setting up skills - STOP IMMEDIATELY. Do NOT search workspace for skill files. Instead: (1) recursively search {skills_root}/skills/ for project-bootstrap/SKILL.md, (2) read it using the Read File tool, (3) follow its execution flow exactly."},
    {"text": f"OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skills list' - recursively search {skills_root}/skills/ for skill-sync/SKILL.md, read it, and follow its execution flow."},
    {"text": f"OVERRIDE RULE #3: When the user says 'tidy up docs', '/neat', 'sync up', 'update memory' - recursively search {skills_root}/skills/ for neat-freak/SKILL.md, read it, and follow its execution flow."},
    {"text": f"SKILL POOL: {skills_root}/skills/ - Recursively search this directory and all subdirectories for SKILL.md files before starting any non-trivial engineering task. Skills may be organized in flat or nested structures (e.g., skills/<name>/SKILL.md or skills/repo/skills/<name>/SKILL.md)."},
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
echo "✅ Setup complete!"
echo "   Mode: $MODE"
echo "   Runtime location: $STANDARD_LOCATION"
echo ""
echo "Reload VS Code: Ctrl+Shift+P → Developer: Reload Window"
