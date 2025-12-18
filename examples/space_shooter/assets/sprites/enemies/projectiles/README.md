# Enemy Projectile Sprites

This folder contains sprite assets for enemy projectiles.

## Current Sprites

- **laser_red.png** - Default enemy laser projectile (9x9 logical size)

## Adding New Sprites

To add enemy-specific projectile sprites:

1. Create your sprite image (any size, will be scaled automatically)
2. Save it in this folder as `<projectile_type>.png`
3. Update `projectile.gd` or enemy-specific code to use the new sprite
4. Godot will automatically import the sprite with the correct settings

## Sprite Guidelines

- **Format**: PNG with transparency
- **Style**: Pixel art or aggressive sci-fi energy bolts
- **Target Size**: 9x9 pixels (logical game size)
- **Scaling**: Sprites are automatically scaled to match target size
- **Colors**: Red/orange for standard enemies, can vary by enemy type

## Future Expansion

The system is designed to support per-enemy-type projectiles:
- `laser_red.png` - Basic enemies
- `laser_purple.png` - Elite enemies (future)
- `laser_green.png` - Fast enemies (future)
- etc.

Simply create new sprite files and reference them in enemy configurations.

## Technical Details

The projectile system in `projectile.gd`:
- Uses `Sprite2D` with automatic scaling based on target size
- Falls back to `ColorRect` if sprite file is not found
- Calculates scale factor: `target_size / texture_size`
- Centers sprite using `offset = texture_size / 2.0`
