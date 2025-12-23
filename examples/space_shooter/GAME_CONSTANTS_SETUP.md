# GameConstants Setup Guide

## What is GameConstants?

`GameConstants` is a centralized singleton that provides all shared constants for the Space Shooter game, eliminating magic numbers and ensuring consistency across the codebase.

## Installation

### Step 1: Register as Autoload

1. Open your project in Godot
2. Go to **Project → Project Settings**
3. Select the **Autoload** tab
4. Click **Add** (the folder icon)
5. Navigate to: `examples/space_shooter/scripts/game_constants.gd`
6. Set **Node Name** to: `SpaceShooterConstants`
7. Click **Add**

### Step 2: Verify Registration

The autoload list should now show:
```
Name: SpaceShooterConstants
Path: res://examples/space_shooter/scripts/game_constants.gd
Enabled: ✓
```

## Usage Examples

### Screen Layout

```gdscript
# Get play area boundaries
var left = SpaceShooterConstants.PLAY_AREA_LEFT  # 480
var right = SpaceShooterConstants.PLAY_AREA_RIGHT  # 1440
var center = SpaceShooterConstants.PLAY_AREA_CENTER  # 960

# Check if position is in play area
if SpaceShooterConstants.is_in_play_area(position):
    print("Inside play area!")
```

### Enemy Movement

```gdscript
# Use constants for boundaries
var left_bound = SpaceShooterConstants.ENEMY_LEFT_BOUND  # 510
var right_bound = SpaceShooterConstants.ENEMY_RIGHT_BOUND  # 1410

# Clamp position to play area
position = SpaceShooterConstants.clamp_to_play_area(position, 30)
```

### Spawning

```gdscript
# Random spawn position at top
enemy.global_position = SpaceShooterConstants.random_spawn_position()

# Or manually
var spawn_x = SpaceShooterConstants.random_play_area_x(50)  # 50px margin
enemy.global_position = Vector2(spawn_x, SpaceShooterConstants.SPAWN_TOP)
```

### Player/Enemy Stats

```gdscript
# Player settings
health_component.max_health = SpaceShooterConstants.PLAYER_MAX_HEALTH
movement_component.speed = SpaceShooterConstants.PLAYER_SPEED

# Enemy settings
enemy.health = SpaceShooterConstants.ENEMY_BASIC_HEALTH
enemy.speed = SpaceShooterConstants.ENEMY_BASIC_SPEED
```

## Benefits

### Before (Magic Numbers)
```gdscript
var left_bound = 320 + 30  # What does 320 mean?
var right_bound = 960 - 30  # Is this correct?
enemy.global_position = Vector2(randf_range(480, 1440), -50)
```

### After (Constants)
```gdscript
var left_bound = SpaceShooterConstants.ENEMY_LEFT_BOUND  # Clear and correct
var right_bound = SpaceShooterConstants.ENEMY_RIGHT_BOUND
enemy.global_position = SpaceShooterConstants.random_spawn_position()
```

## What Was Fixed

The following files have been updated to use `GameConstants`:

1. **`enemy_base.gd`**: Zigzag boundary calculations
2. **`wave_manager.gd`**: Enemy spawn positions
3. **`player_controller.gd`**: Play area bounds

## Available Constants

### Screen Layout
- `SCREEN_WIDTH`, `SCREEN_HEIGHT` (1920x1080)
- `LEFT_PANEL_WIDTH`, `RIGHT_PANEL_WIDTH` (480px each)
- `PLAY_AREA_WIDTH` (960px)
- `PLAY_AREA_LEFT`, `PLAY_AREA_RIGHT`, `PLAY_AREA_CENTER`

### Gameplay Boundaries
- `BOUNDARY_MARGIN` (30px)
- `ENEMY_LEFT_BOUND`, `ENEMY_RIGHT_BOUND`
- `SPAWN_TOP`, `DESPAWN_BOTTOM`

### Player/Enemy Settings
- Health, speed, invincibility duration
- Different enemy types (Basic, Fast, Tank)

### Projectile Settings
- Speed and damage for player/enemy projectiles

### Wave Settings
- Start delay, wave delay

### Helper Functions
- `is_in_play_area(pos)`
- `clamp_to_play_area(pos, margin)`
- `random_play_area_x(margin)`
- `random_spawn_position(margin)`

## Next Steps

Continue replacing magic numbers throughout the codebase:
- [ ] `simple_weapon.gd` - projectile speeds
- [ ] `enemy_factory.gd` - default stats
- [ ] `game_hud.gd` - if any hardcoded values remain
- [ ] Collision layer masks
