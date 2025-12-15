# Platform X - Platformer Example

A complete 2D platformer example demonstrating the MilitiaForge2D framework with Mega Man X-style mechanics.

## 🎮 Features

### Player Mechanics
- **Variable Jump** - Hold jump for higher jumps, tap for short hops
- **Coyote Time** - Jump briefly after leaving platforms
- **Wall Slide & Wall Jump** - Slide down walls and jump off them
- **Air Dash** - Quick horizontal dash with cooldown
- **Charge Shot** - 3-level charge system (normal, half, full)
- **Health System** - Invincibility frames after damage

### Enemies
- **Met** - Ground enemy that hides and shoots
- **Flying Enemy** - Chases player with sine wave movement
- **Turret** - Fixed position, aims and shoots at player

### Level Design
- Platforms and walls
- Spikes (hazards)
- Health pickups
- Checkpoints

## 🕹️ Controls

| Action | Keys |
|--------|------|
| Move | **A/D** or **Arrow Keys** |
| Jump | **Space** or **W** or **Up** |
| Dash | **Shift** |
| Shoot | **X** or **Left Mouse** (hold to charge) |
| Debug Info | **Select/Enter** |

## 🏗️ Architecture

This example demonstrates **5 new platformer components**:

### New Components Created

1. **PlatformerMovement** - `militia_forge/components/movement/platformer_movement.gd`
   - Gravity with terminal velocity
   - Variable jump height
   - Coyote time (0.1s grace period to jump after leaving platform)
   - Jump buffering (press jump before landing)
   - Ground detection via raycasts
   - Optional double jump

2. **WallSlideComponent** - `militia_forge/components/movement/wall_slide_component.gd`
   - Wall detection (left and right)
   - Reduced slide speed on walls
   - Wall jump with directional boost
   - Cooldown to prevent instant re-grab

3. **DashComponent** - `militia_forge/components/movement/dash_component.gd`
   - Fast horizontal dash
   - Cooldown system
   - Air dash limits (1 per jump)
   - Optional invincibility during dash

4. **ChargeShotComponent** - `militia_forge/components/combat/charge_shot_component.gd`
   - 3 charge levels (normal: 10dmg, half: 20dmg, full: 40dmg)
   - Visual/audio feedback hooks
   - Different projectiles per level
   - Configurable charge times

5. **EnemyFactory** - `examples/platformX/scripts/enemy_factory.gd`
   - Factory Pattern for enemy creation
   - Object pooling for performance
   - Batch operations
   - Easy extensibility

### Player Integration

The `PlayerXController` integrates **7 components**:
```gdscript
- PlatformerMovement  # Movement physics
- WallSlideComponent  # Wall mechanics
- DashComponent       # Dash ability
- HealthComponent     # Health system
- InputComponent      # Centralized input
- ChargeShotComponent # Weapon system
- (StateMachine)      # State management (prepared)
```

## 📁 Project Structure

```
examples/platformX/
├── README.md
├── scripts/
│   ├── player_x_controller.gd      # Main player controller
│   ├── enemy_factory.gd             # Factory Pattern for enemies
│   └── enemies/
│       ├── enemy_met.gd             # Met enemy
│       ├── enemy_flying.gd          # Flying enemy
│       └── enemy_turret.gd          # Turret enemy
├── scenes/
│   ├── main_level.tscn              # Main playable level
│   ├── player.tscn                  # Player scene
│   └── enemies/
│       ├── met.tscn
│       ├── flying_enemy.tscn
│       └── turret.tscn
└── ui/
    └── game_hud.gd                  # Health bar, lives, etc
```

## 🎓 Learning Objectives

By studying this example, you learn:

✅ **Component Integration** - How to combine multiple components on one entity  
✅ **Factory Pattern** - Centralized object creation with pooling  
✅ **Platformer Physics** - Gravity, jump, coyote time, wall mechanics  
✅ **Input Management** - Action-based input with InputComponent  
✅ **Health System** - Damage, invincibility, death/respawn  
✅ **Charge Mechanics** - Time-based charge system with levels  

## 🚀 Running the Example

1. Open MilitiaForge2D project in Godot 4.x
2. Navigate to `examples/platformX/scenes/main_level.tscn`
3. Press **F6** to run the scene

## 🔧 Extending the Example

### Adding New Enemy Types

1. Create new enemy script in `scripts/enemies/`
2. Add enemy scene to EnemyFactory exports
3. Add new EnemyType enum value
4. Configure in Factory's `_enemy_scenes` dictionary

### Adding New Abilities

Example: Add double jump power-up
```gdscript
# In player controller
platformer_movement.allow_double_jump = true
platformer_movement.reset_double_jump()
```

### Customizing Mechanics

All mechanics are configurable via exports:
- Jump height: `platformer_movement.jump_velocity`
- Dash speed: `dash.dash_speed`
- Charge times: `charge_shot.charge_time_half/full`
- Wall slide speed: `wall_slide.slide_speed`

## 💡 Tips

- **Coyote time** makes platforming feel more forgiving
- **Jump buffering** lets you press jump slightly before landing
- **Wall jump** pushes you away from the wall automatically
- **Charge shot** - release to fire, don't need to wait for auto-fire
- **Air dash** resets when you land

## 📊 Component Benefits Demonstrated

This example shows:

1. **Reusability** - Same components work for different characters
2. **Modularity** - Easy to add/remove mechanics (e.g., disable dash)
3. **Configurability** - Tune mechanics via editor exports
4. **SOLID Principles** - Each component has single responsibility
5. **Performance** - Object pooling in EnemyFactory

## 🎮 Comparison to Framework Space Shooter Example

| Feature | Space Shooter | PlatformX |
|---------|---------------|-----------|
| Movement | TopDownMovement | PlatformerMovement |
| New Components | 0 (used existing) | 5 (created new) |
| Complexity | Medium | High |
| Demonstrates | Component integration | Component creation + integration |

## 📝 Future Enhancements

Ready to expand? Consider adding:
- Boss enemies with patterns
- Multiple weapons (switch system)
- Power-ups (health, weapon upgrades)
- Checkpoints and lives system
- Parallax scrolling background
- Ladders/climbing
- Moving platforms

---

**Happy platforming!** 🎮⚔️

For more about MilitiaForge2D, see the [main README](../../README.md).
