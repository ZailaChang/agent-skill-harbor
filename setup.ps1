# setup.ps1 — Install skill-harbor for VS Code (Windows local)
# Run once after cloning: .\setup.ps1
# Requires PowerShell 5.1+

$SkillsRoot = $PSScriptRoot
$GlobalInstructions = "$SkillsRoot\GLOBAL_INSTRUCTIONS.md"

# Generate a LOCAL copy of GLOBAL_INSTRUCTIONS.md with real paths (never modify source)
$LocalDir = "$SkillsRoot\.local"
if (-not (Test-Path $LocalDir)) { New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null }
$LocalInstructions = "$LocalDir\GLOBAL_INSTRUCTIONS.md"
$content = Get-Content "$SkillsRoot\GLOBAL_INSTRUCTIONS.md" -Raw
$content = $content -replace '<SKILLS_ROOT>', $SkillsRoot
$content | Set-Content $LocalInstructions -Encoding UTF8
Write-Host "OK Generated: $LocalInstructions"
$UserSettingsPath = "$env:APPDATA\Code\User\settings.json"

# Also check for active profiles
$ProfilesDir = "$env:APPDATA\Code\User\profiles"
$ProfileSettings = @()
if (Test-Path $ProfilesDir) {
    Get-ChildItem $ProfilesDir -Directory | ForEach-Object {
        $p = Join-Path $_.FullName "settings.json"
        $ProfileSettings += $p
    }
}

# Build the Copilot instruction entries to inject
$CopilotInstructions = @(
    @{ text = "OVERRIDE RULE #1 - HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', or any phrase about setting up skills - STOP IMMEDIATELY. Do NOT search workspace for skill files. Instead: (1) recursively search $SkillsRoot\skills\ for project-bootstrap\SKILL.md, (2) read it using the Read File tool, (3) follow its execution flow exactly." },
    @{ text = "OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skills list' - recursively search $SkillsRoot\skills\ for skill-sync\SKILL.md, read it, and follow its execution flow." },
    @{ text = "OVERRIDE RULE #3: When the user says 'tidy up docs', '/neat', 'sync up', 'update memory' - recursively search $SkillsRoot\skills\ for neat-freak\SKILL.md, read it, and follow its execution flow." },
    @{ text = "SKILL POOL: $SkillsRoot\skills\ - Recursively search this directory and all subdirectories for SKILL.md files before starting any non-trivial engineering task. Skills may be organized in flat or nested structures (e.g., skills/<name>/SKILL.md or skills/repo/skills/<name>/SKILL.md)." },
    @{ file = $LocalInstructions }
)

function Merge-Settings {
    param([string]$Target)
    $dir = Split-Path $Target
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Load existing settings or start with empty object — preserves color theme, fonts, etc.
    if (Test-Path $Target) {
        Write-Host "WARNING: $Target already exists - backing up to ${Target}.bak"
        Copy-Item $Target "${Target}.bak" -Force
        try {
            $existing = Get-Content $Target -Raw | ConvertFrom-Json
        } catch {
            Write-Host "  (Could not parse existing JSON - starting fresh)"
            $existing = [PSCustomObject]@{}
        }
    } else {
        $existing = [PSCustomObject]@{}
    }

    # Merge only the Copilot keys — all other settings (theme, fonts, etc.) are left untouched
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.codeGeneration.instructions" -Value $CopilotInstructions
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.testGeneration.instructions" -Value @(@{ file = $LocalInstructions })
    $existing | Add-Member -Force -MemberType NoteProperty `
        -Name "github.copilot.chat.reviewSelection.instructions" -Value @(@{ file = $LocalInstructions })

    $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $Target -Encoding UTF8
    Write-Host "OK Written: $Target"
}

Merge-Settings $UserSettingsPath

# Build list of profiles that actually have a settings.json
$ExistingProfiles = $ProfileSettings | Where-Object { Test-Path $_ }

if ($ExistingProfiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Found $($ExistingProfiles.Count) profile(s) with settings:"
    for ($i = 0; $i -lt $ExistingProfiles.Count; $i++) {
        Write-Host "  [$($i + 1)] $($ExistingProfiles[$i])"
    }
    Write-Host "  [A] All profiles"
    Write-Host "  [Enter] Skip"
    $choice = Read-Host "Merge into which profile?"

    if ($choice -eq 'A' -or $choice -eq 'a') {
        foreach ($p in $ExistingProfiles) { Merge-Settings $p }
    } elseif ($choice -match '^\d+$') {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $ExistingProfiles.Count) {
            Merge-Settings $ExistingProfiles[$idx]
        } else {
            Write-Host "Invalid number - skipping profiles."
        }
    } else {
        Write-Host "Skipping profiles."
    }
}

Write-Host ""
Write-Host "Done. Reload VS Code: Ctrl+Shift+P -> Developer: Reload Window"
Write-Host "Skills root: $SkillsRoot"
