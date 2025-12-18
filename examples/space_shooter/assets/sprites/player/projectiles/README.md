# Player Projectile Sprites

This folder contains sprite assets for player projectiles.

## Current Sprites

- **laser_blue.png** - Default player laser projectile (6x18 logical size)

## Adding New Sprites

To add a new player projectile sprite:

1. Create your sprite image (any size, will be scaled automatically)
2. Save it in this folder as `<projectile_type>.png`
3. Update `projectile.gd` to use the new sprite path
4. Godot will automatically import the sprite with the correct settings

## Sprite Guidelines

- **Format**: PNG with transparency
- **Style**: Pixel art or clean sci-fi laser beams
- **Target Size**: 6x18 pixels (logical game size)
- **Scaling**: Sprites are automatically scaled to match target size
- **Centering**: Sprites are centered automatically via `offset`

## Technical Details

The projectile system in `projectile.gd`:
- Uses `Sprite2D` with automatic scaling based on target size
- Falls back to `ColorRect` if sprite file is not found
- Calculates scale factor: `target_size / texture_size`
- Centers sprite using `offset = texture_size / 2.0`
