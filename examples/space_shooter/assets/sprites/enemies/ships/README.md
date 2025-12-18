# Enemy Ship Sprites

This folder contains sprite assets for enemy ships.

## Current Sprites

- **enemy_basic.png** - Basic enemy ship (48x48 logical size) ✅

## Planned Sprites

- **enemy_fast.png** - Fast enemy ship (48x48 logical size)
- **enemy_tank.png** - Tank enemy ship (48x48 logical size)

## How It Works

The enemy sprite system is **automatic** - sprites are loaded dynamically via code in `enemy_base.gd`:

```gdscript
# Sprites are loaded based on enemy_type
match enemy_type:
	"Basic": loads enemy_basic.png
	"Fast": loads enemy_fast.png
	"Tank": loads enemy_tank.png
```

### Features:
- ✅ **Automatic loading** - No manual Godot Editor configuration needed
- ✅ **Auto-scaling** - Sprites scale to 48x48px target size
- ✅ **Centered** - Uses `sprite.centered = true`
- ✅ **Fallback** - ColorRect if sprite not found

## Sprite Guidelines

- **Format**: PNG with transparency
- **Style**: Pixel art, enemy/alien ships
- **Target Size**: 48x48 pixels (logical game size)
- **Scaling**: Automatic - create at any size
- **Colors**: 
  - Basic: Red tones
  - Fast: Yellow/orange tones
  - Tank: Purple/dark tones

## Adding New Enemy Sprites

1. Create your sprite image (any size)
2. Save as `enemy_<type>.png` in this folder
3. Godot will auto-import
4. Sprite loads automatically when enemy spawns!

**No code changes needed!**
