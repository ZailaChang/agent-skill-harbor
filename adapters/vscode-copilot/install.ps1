# setup.ps1 — Install agent-skill-harbor for VS Code (Windows)
# Requires PowerShell 5.1+
#
# Usage:
#   .\setup.ps1 install   — Copy to standard location (default)
#   .\setup.ps1 dev       — Symlink to dev repo for testing
#   .\setup.ps1 update    — Pull latest and refresh runtime
#   .\setup.ps1 uninstall — Remove from runtime location

param(
    [Parameter(Position=0)]
    [ValidateSet('install', 'dev', 'update', 'uninstall', '')]
    [string]$Mode = 'install'
)

# Paths
$AdapterRoot = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $AdapterRoot -Parent) -Parent  # ../../ from adapters/vscode-copilot/
$ManagedSkillsSource = Join-Path $RepoRoot "skills\managed"
$ExternalSkillsSource = Join-Path $RepoRoot "skills\external"
$FormatScript = Join-Path $AdapterRoot "format.py"
$StandardLocation = "$env:USERPROFILE\.copilot\skills"
$VersionFile = "$StandardLocation\.version"
$UserSettingsPath = "$env:APPDATA\Code\User\settings.json"

# Helper functions
function Read-SkillMetadata {
    <#
    .SYNOPSIS
    Read and parse skill.yaml metadata
    
    .OUTPUTS
    Hashtable with skill metadata, or $null if file doesn't exist
    #>
    param([string]$SkillDir)
    
    $yamlPath = Join-Path $SkillDir "skill.yaml"
    
    if (-not (Test-Path $yamlPath)) {
        return $null
    }
    
    try {
        # Use Python to parse YAML (more reliable than regex)
        $yamlContent = python -c @"
import sys, yaml, json
with open(r'$yamlPath', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
    print(json.dumps(data))
"@
        
        if ($LASTEXITCODE -eq 0) {
            return $yamlContent | ConvertFrom-Json
        }
    } catch {
        Write-Host "   ⚠️  Failed to parse $yamlPath" -ForegroundColor Yellow
    }
    
    return $null
}

function Test-SkillEnabled {
    <#
    .SYNOPSIS
    Check if a skill is enabled for vscode-copilot agent
    
    .OUTPUTS
    $true if enabled, $false otherwise
    #>
    param([string]$SkillDir)
    
    $metadata = Read-SkillMetadata -SkillDir $SkillDir
    
    if (-not $metadata) {
        # No skill.yaml = assume old format, install it
        if (Test-Path (Join-Path $SkillDir "SKILL.md")) {
            return $true
        }
        return $false
    }
    
    # Check if enabled for vscode-copilot
    try {
        $copilotConfig = $metadata.agents.'vscode-copilot'
        return $copilotConfig.enabled -eq $true
    } catch {
        return $false
    }
}

function Write-VersionFile {
    param([string]$Mode, [string]$Source)
    @"
# agent-skill-harbor installation metadata
agent=vscode-copilot
mode=$Mode
source=$Source
timestamp=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
"@ | Out-File -FilePath $VersionFile -Encoding UTF8 -NoNewline
}

function Convert-Skills {
    <#
    .SYNOPSIS
    Convert MANAGED skills to Copilot format (strict: requires skill.yaml)
    #>
    param([string]$OutputDir)
    
    if (-not (Test-Path $ManagedSkillsSource)) {
        Write-Host "   No managed skills directory found" -ForegroundColor DarkGray
        return $false
    }
    
    Write-Host "Converting managed skills..." -ForegroundColor Cyan
    
    # Check if Python is available
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "   Using: $pythonVersion" -ForegroundColor Gray
    } catch {
        Write-Host "   ⚠️  Python not found - cannot convert managed skills" -ForegroundColor Yellow
        return $false
    }
    
    # Check if PyYAML is installed
    $yamlCheck = python -c "import yaml" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ⚠️  PyYAML not installed - cannot convert managed skills" -ForegroundColor Yellow
        Write-Host "   Install with: pip install pyyaml" -ForegroundColor Gray
        return $false
    }
    
    # Filter skills based on YAML metadata
    $enabledSkills = @()
    $skippedSkills = @()
    
    Get-ChildItem $ManagedSkillsSource -Directory | ForEach-Object {
        $skillName = $_.Name
        $skillPath = $_.FullName
        
        if (Test-SkillEnabled -SkillDir $skillPath) {
            $enabledSkills += $_
            Write-Host "   ✓ $skillName (enabled)" -ForegroundColor Gray
        } else {
            $skippedSkills += $skillName
            Write-Host "   ⊘ $skillName (disabled)" -ForegroundColor DarkGray
        }
    }
    
    if ($skippedSkills.Count -gt 0) {
        Write-Host "   Skipping: $($skippedSkills -join ', ')" -ForegroundColor DarkGray
    }
    
    # Convert only enabled skills
    if ($enabledSkills.Count -eq 0) {
        Write-Host "   ⚠️  No managed skills enabled for vscode-copilot" -ForegroundColor Yellow
        return $false
    }
    
    # Convert each enabled skill individually
    foreach ($skill in $enabledSkills) {
        python $FormatScript $skill.FullName $OutputDir 2>&1 | Out-Null
    }
    
    Write-Host "   Converted $($enabledSkills.Count) managed skills" -ForegroundColor Green
    return $true
}

function Copy-ExternalSkills {
    <#
    .SYNOPSIS
    Copy EXTERNAL skills as-is (lenient: just needs SKILL.md)
    Handles both flat and nested repo structures
    #>
    param([string]$OutputDir)
    
    if (-not (Test-Path $ExternalSkillsSource)) {
        Write-Host "   No external skills directory found" -ForegroundColor DarkGray
        return 0
    }
    
    $externalItems = Get-ChildItem $ExternalSkillsSource -Directory
    if ($externalItems.Count -eq 0) {
        Write-Host "   No external skills found" -ForegroundColor DarkGray
        return 0
    }
    
    Write-Host "Copying external skills..." -ForegroundColor Cyan
    
    $copiedCount = 0
    
    foreach ($item in $externalItems) {
        $itemName = $item.Name
        $skillMd = Join-Path $item.FullName "SKILL.md"
        
        # Case 1: Flat structure (SKILL.md at root)
        if (Test-Path $skillMd) {
            $targetDir = Join-Path $OutputDir $itemName
            Copy-Item -Path $item.FullName -Destination $targetDir -Recurse -Force
            Write-Host "   ✓ $itemName (copied as-is)" -ForegroundColor Gray
            $copiedCount++
            continue
        }
        
        # Case 2: Nested repo structure (has skills/ subdirectory)
        $nestedSkillsDir = Join-Path $item.FullName "skills"
        if (Test-Path $nestedSkillsDir) {
            Write-Host "   📦 $itemName (nested repo):" -ForegroundColor Cyan
            $nestedSkills = Get-ChildItem $nestedSkillsDir -Directory
            
            foreach ($nestedSkill in $nestedSkills) {
                $nestedSkillMd = Join-Path $nestedSkill.FullName "SKILL.md"
                if (Test-Path $nestedSkillMd) {
                    $targetDir = Join-Path $OutputDir $nestedSkill.Name
                    Copy-Item -Path $nestedSkill.FullName -Destination $targetDir -Recurse -Force
                    Write-Host "      ✓ $($nestedSkill.Name)" -ForegroundColor Gray
                    $copiedCount++
                } else {
                    Write-Host "      ⊘ $($nestedSkill.Name) (no SKILL.md)" -ForegroundColor DarkGray
                }
            }
            continue
        }
        
        # Case 3: Unknown structure
        Write-Host "   ⊘ $itemName (no SKILL.md, not a nested repo)" -ForegroundColor Yellow
    }
    
    if ($copiedCount -gt 0) {
        Write-Host "   Copied $copiedCount external skills" -ForegroundColor Green
    }
    
    return $copiedCount
}

function Install-Skills {
    param([string]$Mode)
    
    Write-Host "Installing to: $StandardLocation" -ForegroundColor Cyan
    
    if ($Mode -eq 'dev') {
        # Dev mode: create symlink to source skills (NOT to adapter dir)
        # This allows live editing of skills
        if (Test-Path $StandardLocation) {
            Remove-Item $StandardLocation -Recurse -Force
        }
        
        try {
            # Symlink the entire repo root so all files are accessible
            New-Item -ItemType SymbolicLink -Path $StandardLocation -Target $RepoRoot -Force | Out-Null
            Write-Host "✅ Created symlink: $StandardLocation → $RepoRoot" -ForegroundColor Green
            Write-Host "   Skills will be read from: $RepoRoot\skills\" -ForegroundColor Gray
            Write-VersionFile -Mode 'dev' -Source $RepoRoot
        } catch {
            Write-Host "❌ Failed to create symlink. Try running as Administrator or use 'install' mode." -ForegroundColor Red
            exit 1
        }
    } else {
        # Install mode: convert and copy files
        if (Test-Path $StandardLocation) {
            Write-Host "⚠️  Existing installation found - backing up..." -ForegroundColor Yellow
            $BackupPath = "$StandardLocation.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Move-Item $StandardLocation $BackupPath -Force
            Write-Host "   Backed up to: $BackupPath" -ForegroundColor Gray
        }
        
        # Create temp directory for conversion
        $TempDir = Join-Path $env:TEMP "agent-skill-harbor-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        
        # TWO-TIER INSTALLATION
        Write-Host ""
        
        # 1. Convert managed skills (requires skill.yaml)
        $convertedManaged = Convert-Skills -OutputDir "$TempDir\skills"
        
        # 2. Copy external skills (just needs SKILL.md)
        $copiedExternal = Copy-ExternalSkills -OutputDir "$TempDir\skills"
        
        $totalSkills = if ($convertedManaged) { (Get-ChildItem "$TempDir\skills" -Directory).Count } else { 0 }
        
        if ($totalSkills -eq 0) {
            Write-Host ""
            Write-Host "❌ No skills to install" -ForegroundColor Red
            Remove-Item $TempDir -Recurse -Force
            exit 1
        }
        
        Write-Host ""
        Write-Host "Total skills ready: $totalSkills" -ForegroundColor Green
        
        # Copy converted skills to runtime location
        New-Item -ItemType Directory -Path $StandardLocation -Force | Out-Null
        Copy-Item -Path "$TempDir\skills\*" -Destination $StandardLocation -Recurse -Force
        
        # Copy .local directory structure if it exists in repo
        $LocalDir = Join-Path $RepoRoot ".local"
        if (Test-Path $LocalDir) {
            Copy-Item -Path $LocalDir -Destination $StandardLocation -Recurse -Force
        }
        
        # Clean up temp directory
        Remove-Item $TempDir -Recurse -Force
        
        Write-Host "✅ Installed to: $StandardLocation" -ForegroundColor Green
        Write-VersionFile -Mode 'install' -Source $RepoRoot
    }
}

function Uninstall-Skills {
    if (-not (Test-Path $StandardLocation)) {
        Write-Host "No installation found at: $StandardLocation" -ForegroundColor Yellow
        return
    }
    
    $BackupPath = "$StandardLocation.removed.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item $StandardLocation $BackupPath -Force
    Write-Host "✅ Removed installation (backed up to: $BackupPath)" -ForegroundColor Green
    Write-Host "   VS Code settings retain the path but will not find skills." -ForegroundColor Gray
}

function Update-Skills {
    if (-not (Test-Path $VersionFile)) {
        Write-Host "❌ No installation found. Run '.\setup.ps1 install' first." -ForegroundColor Red
        exit 1
    }
    
    $VersionData = Get-Content $VersionFile | ConvertFrom-StringData
    $CurrentMode = $VersionData.mode
    
    Write-Host "Current mode: $CurrentMode" -ForegroundColor Cyan
    
    # Pull latest from git if in a git repo
    Push-Location $RepoRoot
    try {
        if (Test-Path ".git") {
            Write-Host "Pulling latest changes..." -ForegroundColor Cyan
            git pull
        } else {
            Write-Host "⚠️  Not a git repository - skipping pull" -ForegroundColor Yellow
        }
    } finally {
        Pop-Location
    }
    
    # Reinstall with same mode
    Install-Skills -Mode $CurrentMode
    Write-Host "✅ Updated to latest version" -ForegroundColor Green
}

# Main execution
switch ($Mode) {
    'uninstall' {
        Uninstall-Skills
        Write-Host "`nNote: VS Code settings still reference $StandardLocation" -ForegroundColor Gray
        Write-Host "      They are harmless and can be left in place." -ForegroundColor Gray
        exit 0
    }
    'update' {
        Update-Skills
        # Continue to update VS Code settings
    }
    default {
        Install-Skills -Mode $Mode
        # Continue to update VS Code settings
    }
}

# Generate GLOBAL_INSTRUCTIONS.md with standard path
$LocalDir = "$StandardLocation\.local"
if (-not (Test-Path $LocalDir)) { New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null }
$LocalInstructions = "$LocalDir\GLOBAL_INSTRUCTIONS.md"
$GlobalInstructionsSource = Join-Path $RepoRoot "GLOBAL_INSTRUCTIONS.md"
$content = Get-Content $GlobalInstructionsSource -Raw
$content = $content -replace '<SKILLS_ROOT>', $StandardLocation
$utf8NoBOM = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($LocalInstructions, $content, $utf8NoBOM)
Write-Host "✅ Generated: $LocalInstructions" -ForegroundColor Green

# Collect profile settings
$ProfilesDir = "$env:APPDATA\Code\User\profiles"
$ProfileSettings = @()
if (Test-Path $ProfilesDir) {
    Get-ChildItem $ProfilesDir -Directory | ForEach-Object {
        $p = Join-Path $_.FullName "settings.json"
        if (Test-Path $p) { $ProfileSettings += $p }
    }
}

# Build the Copilot instruction entries (always reference standard location)
$CopilotInstructions = @(
    @{ text = "OVERRIDE RULE #1 - HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', or any phrase about setting up skills - STOP IMMEDIATELY. Do NOT search workspace for skill files. Instead: (1) recursively search $StandardLocation\skills\ for project-bootstrap\SKILL.md, (2) read it using the Read File tool, (3) follow its execution flow exactly." },
    @{ text = "OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skills list' - recursively search $StandardLocation\skills\ for skill-sync\SKILL.md, read it, and follow its execution flow." },
    @{ text = "OVERRIDE RULE #3: When the user says 'tidy up docs', '/neat', 'sync up', 'update memory' - recursively search $StandardLocation\skills\ for neat-freak\SKILL.md, read it, and follow its execution flow." },
    @{ text = "SKILL POOL: $StandardLocation\skills\ - Recursively search this directory and all subdirectories for SKILL.md files before starting any non-trivial engineering task. Skills may be organized in flat or nested structures (e.g., skills/<name>/SKILL.md or skills/repo/skills/<name>/SKILL.md)." },
    @{ file = $LocalInstructions }
)

function Merge-Settings {
    param([string]$Target)
    $dir = Split-Path $Target
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Load existing settings or start with empty object
    if (Test-Path $Target) {
        try {
            $existing = Get-Content $Target -Raw | ConvertFrom-Json
        } catch {
            Write-Host "  ⚠️  Could not parse existing JSON - starting fresh" -ForegroundColor Yellow
            $existing = [PSCustomObject]@{}
        }
    } else {
        $existing = [PSCustomObject]@{}
    }

    # Merge only the Copilot keys — all other settings are preserved
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.codeGeneration.instructions" -Value $CopilotInstructions
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.testGeneration.instructions" -Value @(@{ file = $LocalInstructions })
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.reviewSelection.instructions" -Value @(@{ file = $LocalInstructions })

    $json = $existing | ConvertTo-Json -Depth 10
    $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Target, $json + "`n", $utf8NoBOM)
    Write-Host "✅ Written: $Target" -ForegroundColor Green
}

Merge-Settings $UserSettingsPath

# Build list of profiles that actually have a settings.json
if ($ProfileSettings.Count -gt 0) {
    Write-Host ""
    Write-Host "Found $($ProfileSettings.Count) profile(s) with settings:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ProfileSettings.Count; $i++) {
        Write-Host "  [$($i + 1)] $($ProfileSettings[$i])"
    }
    Write-Host "  [A] All profiles"
    Write-Host "  [Enter] Skip"
    $choice = Read-Host "Merge into which profile?"

    if ($choice -eq 'A' -or $choice -eq 'a') {
        foreach ($p in $ProfileSettings) { Merge-Settings $p }
    } elseif ($choice -match '^\d+$') {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $ProfileSettings.Count) {
            Merge-Settings $ProfileSettings[$idx]
        } else {
            Write-Host "Invalid number - skipping profiles." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skipping profiles." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "   Mode: $Mode" -ForegroundColor Cyan
Write-Host "   Runtime location: $StandardLocation" -ForegroundColor Cyan
Write-Host ""
Write-Host "Reload VS Code: Ctrl+Shift+P → Developer: Reload Window" -ForegroundColor Yellow
