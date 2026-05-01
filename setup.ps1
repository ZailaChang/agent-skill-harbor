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
    @{ text = "OVERRIDE RULE #1 - HIGHEST PRIORITY: When the user says 'setup skills', 'setup agent skills', '/bootstrap', '/project-setup', 'import skills', or any phrase about setting up skills - STOP IMMEDIATELY. Do NOT search workspace for skill files. Instead: (1) use the Read File tool to read $SkillsRoot\skills\project-bootstrap\SKILL.md, (2) follow its execution flow exactly." },
    @{ text = "OVERRIDE RULE #2: When the user says 'sync skills', '/skills', '/skill-sync', 'skills list' - use the Read File tool to read $SkillsRoot\skills\skill-sync\SKILL.md and follow its execution flow." },
    @{ text = "OVERRIDE RULE #3: When the user says 'tidy up docs', '/neat', 'sync up', 'update memory' - use the Read File tool to read $SkillsRoot\skills\neat-freak\SKILL.md and follow its execution flow." },
    @{ text = "SKILL POOL: $SkillsRoot\skills\ - Check this directory for relevant SKILL.md files before starting any non-trivial engineering task." },
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

# Only prompt for profiles that already have a settings.json (skip empty/unused profiles)
foreach ($p in $ProfileSettings) {
    if (-not (Test-Path $p)) { continue }
    $answer = Read-Host "Merge into profile settings? $p (y/N)"
    if ($answer -eq 'y') { Merge-Settings $p }
}

Write-Host ""
Write-Host "Done. Reload VS Code: Ctrl+Shift+P -> Developer: Reload Window"
Write-Host "Skills root: $SkillsRoot"
