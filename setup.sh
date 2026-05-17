#!/usr/bin/env bash
# setup.sh — Agent-agnostic installer for agent-skill-harbor
# Detects your AI assistant and installs skills in the correct format
#
# Usage:
#   bash setup.sh                    # Auto-detect agent
#   bash setup.sh --agent copilot    # Force specific agent
#   bash setup.sh install            # Pass mode to adapter
#   bash setup.sh --agent copilot dev  # Specify agent and mode

set -e

SOURCE_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
AGENT=""
MODE="install"
AUTO_DETECT=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT="$2"
      AUTO_DETECT=false
      shift 2
      ;;
    install|dev|update|uninstall)
      MODE="$1"
      shift
      ;;
    --help|-h)
      cat <<EOF
agent-skill-harbor setup

Usage:
  bash setup.sh [--agent AGENT] [MODE]

Agents:
  vscode-copilot    GitHub Copilot in VS Code (default if detected)
  claude-desktop    Anthropic Claude Desktop (coming soon)
  cursor            Cursor IDE (coming soon)

Modes:
  install           Copy to standard location (default)
  dev               Symlink to source for development
  update            Pull latest and reinstall
  uninstall         Remove from runtime location

Examples:
  bash setup.sh                      # Auto-detect agent, install mode
  bash setup.sh dev                  # Auto-detect agent, dev mode
  bash setup.sh --agent copilot dev  # Force Copilot, dev mode

EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Run 'bash setup.sh --help' for usage"
      exit 1
      ;;
  esac
done

# Auto-detect agent if not specified
if [[ "$AUTO_DETECT" == "true" ]]; then
  echo "Detecting AI assistant..."
  
  # Check for VS Code + Copilot
  if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
    if grep -q "github.copilot" "$HOME/.config/Code/User/settings.json" 2>/dev/null; then
      AGENT="vscode-copilot"
      echo "   Found: GitHub Copilot in VS Code"
    fi
  elif [[ -f "$HOME/Library/Application Support/Code/User/settings.json" ]]; then
    if grep -q "github.copilot" "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null; then
      AGENT="vscode-copilot"
      echo "   Found: GitHub Copilot in VS Code"
    fi
  fi
  
  # Check for Claude Desktop (macOS)
  if [[ -z "$AGENT" ]] && [[ -d "$HOME/Library/Application Support/Claude" ]]; then
    AGENT="claude-desktop"
    echo "   Found: Claude Desktop"
  fi
  
  # Check for Cursor
  if [[ -z "$AGENT" ]] && [[ -d "$HOME/.config/Cursor" || -d "$HOME/Library/Application Support/Cursor" ]]; then
    AGENT="cursor"
    echo "   Found: Cursor IDE"
  fi
  
  # Fallback
  if [[ -z "$AGENT" ]]; then
    echo ""
    echo "No supported AI assistant detected."
    echo ""
    echo "Supported assistants:"
    echo "  - GitHub Copilot (VS Code)"
    echo "  - Claude Desktop (coming soon)"
    echo "  - Cursor IDE (coming soon)"
    echo ""
    echo "If you have one installed, specify it manually:"
    echo "  bash setup.sh --agent vscode-copilot"
    exit 1
  fi
fi

# Check if adapter exists
ADAPTER_DIR="$SOURCE_ROOT/adapters/$AGENT"
if [[ ! -d "$ADAPTER_DIR" ]]; then
  echo "Adapter not found: $AGENT"
  echo "   Expected: $ADAPTER_DIR"
  echo ""
  echo "Available adapters:"
  for adapter in "$SOURCE_ROOT/adapters"/*; do
    if [[ -d "$adapter" ]]; then
      echo "  - $(basename "$adapter")"
    fi
  done
  exit 1
fi

# Check if adapter has install script
ADAPTER_SCRIPT="$ADAPTER_DIR/install.sh"
if [[ ! -f "$ADAPTER_SCRIPT" ]]; then
  echo "Adapter not yet implemented: $AGENT"
  echo "   Missing: $ADAPTER_SCRIPT"
  echo ""
  echo "This adapter is a placeholder. Check the README for implementation status."
  exit 1
fi

# Run adapter
echo ""
echo "Running $AGENT adapter (mode: $MODE)..."
echo ""

bash "$ADAPTER_SCRIPT" "$MODE"
