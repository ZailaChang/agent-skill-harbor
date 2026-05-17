# setup.ps1 — Agent-agnostic installer for agent-skill-harbor
# Detects your AI assistant and installs skills in the correct format
#
# Usage:
#   .\setup.ps1                      # Auto-detect agent
#   .\setup.ps1 -Agent copilot       # Force specific agent
#   .\setup.ps1 install              # Pass mode to adapter
#   .\setup.ps1 -Agent copilot -Mode dev  # Specify agent and mode

param(
    [Parameter(Position=0)]
    [ValidateSet('install', 'dev', 'update', 'uninstall', '')]
    [string]$Mode = 'install',
    
    [Parameter()]
    [ValidateSet('vscode-copilot', 'claude-desktop', 'cursor', '')]
    [string]$Agent = '',
    
    [Parameter()]
    [switch]$Help
)

$SourceRoot = $PSScriptRoot

# Show help
if ($Help) {
    @"
agent-skill-harbor setup

Usage:
  .\setup.ps1 [-Agent AGENT] [-Mode MODE]

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
  .\setup.ps1                         # Auto-detect agent, install mode
  .\setup.ps1 dev                     # Auto-detect agent, dev mode
  .\setup.ps1 -Agent copilot -Mode dev  # Force Copilot, dev mode

"@
    exit 0
}

# Auto-detect agent if not specified
if (-not $Agent) {
    Write-Host "Detecting AI assistant..." -ForegroundColor Cyan
    
    # Check for VS Code + Copilot
    $VsCodeSettings = "$env:APPDATA\Code\User\settings.json"
    if (Test-Path $VsCodeSettings) {
        $settingsContent = Get-Content $VsCodeSettings -Raw
        if ($settingsContent -match 'github\.copilot') {
            $Agent = 'vscode-copilot'
            Write-Host "   Found: GitHub Copilot in VS Code" -ForegroundColor Green
        }
    }
    
    # Check for Claude Desktop (Windows)
    if (-not $Agent) {
        $ClaudePath = "$env:APPDATA\Claude"
        if (Test-Path $ClaudePath) {
            $Agent = 'claude-desktop'
            Write-Host "   Found: Claude Desktop" -ForegroundColor Green
        }
    }
    
    # Check for Cursor
    if (-not $Agent) {
        $CursorPath = "$env:APPDATA\Cursor"
        if (Test-Path $CursorPath) {
            $Agent = 'cursor'
            Write-Host "   Found: Cursor IDE" -ForegroundColor Green
        }
    }
    
    # Fallback
    if (-not $Agent) {
        Write-Host ""
        Write-Host "No supported AI assistant detected." -ForegroundColor Red
        Write-Host ""
        Write-Host "Supported assistants:"
        Write-Host "  - GitHub Copilot (VS Code)"
        Write-Host "  - Claude Desktop (coming soon)"
        Write-Host "  - Cursor IDE (coming soon)"
        Write-Host ""
        Write-Host "If you have one installed, specify it manually:"
        Write-Host "  .\setup.ps1 -Agent vscode-copilot"
        exit 1
    }
}

# Show which skills will be installed (YAML-driven preview)
function Show-SkillPreview {
    param([string]$Agent)
    
    Write-Host ""
    Write-Host "Skills for $Agent" ":" -ForegroundColor Cyan
    
    $skillsDir = Join-Path $SourceRoot "skills"
    $managedDir = Join-Path $skillsDir "managed"
    $externalDir = Join-Path $skillsDir "external"
    
    # Check if Python + PyYAML available
    $pythonAvailable = $false
    try {
        python -c "import yaml" 2>&1 | Out-Null
        $pythonAvailable = $LASTEXITCODE -eq 0
    } catch {}
    
    # MANAGED SKILLS (require skill.yaml)
    if (Test-Path $managedDir) {
        Write-Host "  Managed (vendor-neutral):" -ForegroundColor White
        
        if (-not $pythonAvailable) {
            Write-Host "     (Cannot preview - Python or PyYAML not installed)" -ForegroundColor DarkGray
        } else {
            $managedCount = 0
            $disabledCount = 0
            
            Get-ChildItem $managedDir -Directory | Sort-Object Name | ForEach-Object {
                $skillName = $_.Name
                $yamlPath = Join-Path $_.FullName "skill.yaml"
                
                if (Test-Path $yamlPath) {
                    try {
                        $metadata = python -c @"
import sys, yaml, json
with open(r'$yamlPath', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
    print(json.dumps(data))
"@ | ConvertFrom-Json
                        
                        $agentKey = $Agent
                        if ($Agent -eq 'copilot') { $agentKey = 'vscode-copilot' }
                        
                        $agentConfig = $metadata.agents.$agentKey
                        if ($agentConfig.enabled -eq $true) {
                            Write-Host "     ✓ $skillName" -ForegroundColor Green
                            $managedCount++
                        } else {
                            Write-Host "     ⊘ $skillName (disabled)" -ForegroundColor DarkGray
                            $disabledCount++
                        }
                    } catch {
                        Write-Host "     ? $skillName (parse error)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "     ⚠ $skillName (no skill.yaml)" -ForegroundColor Yellow
                }
            }
            
            if ($managedCount -eq 0 -and $disabledCount -eq 0) {
                Write-Host "     (No managed skills)" -ForegroundColor DarkGray
            }
        }
    }
    
    # EXTERNAL SKILLS (just need SKILL.md)
    if (Test-Path $externalDir) {
        $externalItems = Get-ChildItem $externalDir -Directory
        
        if ($externalItems.Count -gt 0) {
            Write-Host "  External (copied as-is):" -ForegroundColor White
            
            $externalCount = 0
            foreach ($item in $externalItems) {
                $itemName = $item.Name
                $skillMd = Join-Path $item.FullName "SKILL.md"
                
                # Flat structure
                if (Test-Path $skillMd) {
                    Write-Host "     ✓ $itemName" -ForegroundColor Cyan
                    $externalCount++
                    continue
                }
                
                # Nested repo structure
                $nestedSkillsDir = Join-Path $item.FullName "skills"
                if (Test-Path $nestedSkillsDir) {
                    Write-Host "     📦 $itemName (nested repo):" -ForegroundColor Cyan
                    $nestedSkills = Get-ChildItem $nestedSkillsDir -Directory
                    
                    foreach ($nestedSkill in $nestedSkills) {
                        $nestedSkillMd = Join-Path $nestedSkill.FullName "SKILL.md"
                        if (Test-Path $nestedSkillMd) {
                            Write-Host "        ✓ $($nestedSkill.Name)" -ForegroundColor Cyan
                            $externalCount++
                        }
                    }
                    continue
                }
                
                # Unknown structure
                Write-Host "     ⊘ $itemName (no SKILL.md)" -ForegroundColor DarkGray
            }
            
            if ($externalCount -eq 0) {
                Write-Host "     (No valid external skills)" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host ""
}

# Check if adapter exists
$AdapterDir = Join-Path $SourceRoot "adapters\$Agent"
if (-not (Test-Path $AdapterDir)) {
    Write-Host "Adapter not found: $Agent" -ForegroundColor Red
    Write-Host "   Expected: $AdapterDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Available adapters:"
    Get-ChildItem (Join-Path $SourceRoot "adapters") -Directory | ForEach-Object {
        Write-Host "  - $($_.Name)"
    }
    exit 1
}

# Check if adapter has install script
$AdapterScript = Join-Path $AdapterDir "install.ps1"
if (-not (Test-Path $AdapterScript)) {
    Write-Host "Adapter not yet implemented: $Agent" -ForegroundColor Red
    Write-Host "   Missing: $AdapterScript" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This adapter is a placeholder. Check the README for implementation status."
    exit 1
}

# Show preview of skills to be installed
if ($Mode -eq 'install' -or $Mode -eq 'dev') {
    Show-SkillPreview -Agent $Agent
}

# Run adapter
Write-Host ""
Write-Host "Running $Agent adapter (mode: $Mode)..." -ForegroundColor Cyan
Write-Host ""

& $AdapterScript $Mode
