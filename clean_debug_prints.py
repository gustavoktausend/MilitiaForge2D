#!/usr/bin/env python3
"""
Script to clean debug print() statements from Space Shooter scripts.
Keeps only critical logs (errors, warnings, death events).
"""

import re
import os
from pathlib import Path

# Patterns to KEEP (critical logs)
KEEP_PATTERNS = [
    r'print.*\[ERROR\]',
    r'print.*\[WARNING\]',
    r'print.*DIED',
    r'print.*GAME OVER',
    r'print.*💀',
    r'push_error',
    r'push_warning',
]

# Patterns to REMOVE (debug logs)
REMOVE_PATTERNS = [
    r'^\s*print\(".*╔.*"\)',  # Box drawing characters
    r'^\s*print\(".*║.*"\)',
    r'^\s*print\(".*╚.*"\)',
    r'^\s*print\(".*═.*"\)',
    r'^\s*print\(".*━.*"\)',
    r'^\s*print\(\[.*\].*\)',  # Lists/arrays in prints
]

def should_keep_line(line):
    """Check if a print line should be kept."""
    # Keep non-print lines
    if 'print(' not in line and 'print"' not in line:
        return True

    # Keep critical logs
    for pattern in KEEP_PATTERNS:
        if re.search(pattern, line, re.IGNORECASE):
            return True

    return False

def clean_file(filepath):
    """Remove debug prints from a file."""
    print(f"Processing: {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    removed_count = 0

    for line in lines:
        if should_keep_line(line):
            new_lines.append(line)
        else:
            removed_count += 1
            # Keep the line but comment it out for review
            # new_lines.append('# ' + line)

    if removed_count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"  ✓ Removed {removed_count} debug prints")
        return removed_count
    else:
        print(f"  - No prints to remove")
        return 0

def main():
    """Main function to clean all Space Shooter scripts."""
    base_path = Path(__file__).parent / 'examples' / 'space_shooter' / 'scripts'

    # Files to clean
    files_to_clean = [
        'player_controller.gd',
        'enemy_base.gd',
        'game_controller.gd',
        'wave_manager.gd',
        'enemy_factory.gd',
        'entity_pool_manager.gd',
        'projectile.gd',
        'phase_system/phase_manager.gd',
    ]

    ui_files = [
        '../ui/main_menu.gd',
        '../ui/game_hud.gd',
        '../ui/weapons_hud.gd',
        'loadout_selection_ui.gd',
        'pilot_selection_ui.gd',
    ]

    total_removed = 0

    print("="*60)
    print("Cleaning debug prints from Space Shooter scripts")
    print("="*60)

    for file in files_to_clean + ui_files:
        filepath = base_path / file
        if filepath.exists():
            total_removed += clean_file(filepath)
        else:
            print(f"File not found: {filepath}")

    print("="*60)
    print(f"✓ Total: Removed {total_removed} debug print statements")
    print("="*60)

if __name__ == '__main__':
    main()
