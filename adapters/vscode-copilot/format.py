#!/usr/bin/env python3
"""
format.py - VS Code Copilot Format Converter

Normalizes skills from multiple formats into Copilot's SKILL.md format.

Supported input formats:
1. NEW: skill.yaml + content.md (vendor-neutral)
2. OLD: SKILL.md only (Copilot native - copied as-is)

Usage:
    python format.py <skill_dir> <output_dir>
    python format.py --all <skills_root> <output_root>
"""

import sys
import yaml
from pathlib import Path
from typing import Dict, Any, Optional
import shutil


def detect_skill_format(skill_dir: Path) -> str:
    """
    Detect which format the skill uses.
    
    Returns:
        'new': skill.yaml + content.md
        'old': SKILL.md only
        'unknown': neither format
    """
    has_yaml = (skill_dir / "skill.yaml").exists()
    has_content_md = (skill_dir / "content.md").exists()
    has_skill_md = (skill_dir / "SKILL.md").exists()
    
    if has_yaml and has_content_md:
        return 'new'
    elif has_skill_md:
        return 'old'
    else:
        return 'unknown'


def load_skill_metadata(skill_dir: Path) -> Optional[Dict[str, Any]]:
    """Load and parse skill.yaml (returns None if not exists)"""
    skill_yaml = skill_dir / "skill.yaml"
    
    if not skill_yaml.exists():
        return None
    
    with open(skill_yaml, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    
    return data


def load_skill_content(skill_dir: Path) -> Optional[str]:
    """Load content.md (returns None if not exists)"""
    content_md = skill_dir / "content.md"
    
    if not content_md.exists():
        return None
    
    with open(content_md, 'r', encoding='utf-8') as f:
        return f.read()


def generate_copilot_frontmatter(metadata: Dict[str, Any]) -> str:
    """Generate YAML frontmatter for Copilot SKILL.md"""
    
    # Extract relevant fields
    name = metadata.get('name', 'unknown')
    description = metadata.get('description', '')
    
    # Build trigger phrases for frontmatter
    triggers = metadata.get('triggers', {})
    natural_triggers = triggers.get('natural', [])
    command_triggers = triggers.get('command', [])
    
    # Combine all triggers into description
    all_triggers = natural_triggers + command_triggers
    trigger_desc = ', '.join(f'"{t}"' for t in all_triggers[:5])  # Limit to 5
    
    if trigger_desc:
        full_description = f"{description}\n  MUST trigger when the user says: {trigger_desc}"
    else:
        full_description = description
    
    # Build frontmatter
    frontmatter = {
        'name': name,
        'description': full_description
    }
    
    return yaml.dump(frontmatter, default_flow_style=False, allow_unicode=True)


def convert_skill(skill_dir: Path, output_dir: Path) -> None:
    """Convert a single skill to Copilot format (supports multiple input formats)"""
    
    skill_name = skill_dir.name
    skill_format = detect_skill_format(skill_dir)
    
    print(f"Converting {skill_name}...", file=sys.stderr)
    
    # Create output directory
    output_skill_dir = output_dir / skill_name
    output_skill_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_skill_dir / "SKILL.md"
    
    if skill_format == 'new':
        # NEW FORMAT: skill.yaml + content.md
        # Convert to SKILL.md with frontmatter
        metadata = load_skill_metadata(skill_dir)
        content = load_skill_content(skill_dir)
        
        if not metadata or not content:
            print(f"  ⚠️  Skipping {skill_name} (incomplete new format)", file=sys.stderr)
            return
        
        # Check if enabled for vscode-copilot
        agents = metadata.get('agents', {})
        copilot_config = agents.get('vscode-copilot', {})
        
        if not copilot_config.get('enabled', False):
            print(f"  ⚠️  Skipping {skill_name} (not enabled for vscode-copilot)", file=sys.stderr)
            return
        
        # Generate frontmatter
        frontmatter = generate_copilot_frontmatter(metadata)
        
        # Combine into SKILL.md format
        skill_md = f"---\n{frontmatter}---\n\n{content}"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(skill_md)
        
        print(f"  ✅ {output_file} (converted from new format)", file=sys.stderr)
        
    elif skill_format == 'old':
        # OLD FORMAT: SKILL.md already exists
        # Copy as-is (already in correct format!)
        source_skill_md = skill_dir / "SKILL.md"
        shutil.copy2(source_skill_md, output_file)
        
        print(f"  ✅ {output_file} (copied from old format)", file=sys.stderr)
        
    else:
        # UNKNOWN FORMAT
        print(f"  ⚠️  Skipping {skill_name} (no skill.yaml+content.md or SKILL.md found)", file=sys.stderr)
        return
    
    # Copy references directory if it exists (both formats)
    ref_dir = skill_dir / "references"
    if ref_dir.exists() and ref_dir.is_dir():
        output_ref_dir = output_skill_dir / "references"
        output_ref_dir.mkdir(exist_ok=True)
        
        for ref_file in ref_dir.iterdir():
            if ref_file.is_file():
                shutil.copy2(ref_file, output_ref_dir / ref_file.name)


def convert_all_skills(skills_root: Path, output_root: Path) -> None:
    """Convert all skills in a directory (supports multiple formats)"""
    
    if not skills_root.exists():
        raise FileNotFoundError(f"Skills directory not found: {skills_root}")
    
    output_root.mkdir(parents=True, exist_ok=True)
    
    converted = 0
    skipped = 0
    
    for skill_dir in sorted(skills_root.iterdir()):
        if not skill_dir.is_dir():
            continue
        
        # Detect format (don't require skill.yaml)
        skill_format = detect_skill_format(skill_dir)
        
        if skill_format == 'unknown':
            print(f"⚠️  {skill_dir.name}: No recognized format (need skill.yaml+content.md or SKILL.md)", file=sys.stderr)
            skipped += 1
            continue
        
        try:
            convert_skill(skill_dir, output_root)
            converted += 1
        except Exception as e:
            print(f"❌ {skill_dir.name}: {e}", file=sys.stderr)
            skipped += 1
    
    print(f"\n✅ Converted {converted} skills, skipped {skipped}", file=sys.stderr)


def main():
    if len(sys.argv) < 3:
        print("Usage:", file=sys.stderr)
        print("  python format.py <skill_dir> <output_dir>", file=sys.stderr)
        print("  python format.py --all <skills_root> <output_root>", file=sys.stderr)
        sys.exit(1)
    
    if sys.argv[1] == '--all':
        if len(sys.argv) != 4:
            print("Error: --all requires <skills_root> <output_root>", file=sys.stderr)
            sys.exit(1)
        
        skills_root = Path(sys.argv[2])
        output_root = Path(sys.argv[3])
        convert_all_skills(skills_root, output_root)
    else:
        skill_dir = Path(sys.argv[1])
        output_dir = Path(sys.argv[2])
        convert_skill(skill_dir, output_dir)


if __name__ == '__main__':
    main()
