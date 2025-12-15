# Space Shooter - MilitiaForge2D Example Game

A complete vertical space shooter demonstrating the capabilities of the MilitiaForge2D framework.

## 🎮 Game Overview

Space Shooter is a classic vertical scrolling shoot-'em-up where you pilot a spaceship through waves of enemies, collecting power-ups and trying to achieve the highest score.

### Features

- **5 Progressive Waves** - Increasing difficulty with varied enemy patterns
- **3 Enemy Types** - Basic, Fast, and Tank enemies with different behaviors
- **Power-Up System** - Weapon upgrades and health pickups
- **Score & Combo System** - Build combos for higher scores
- **Health System** - Health bar with invincibility frames
- **Smooth Movement** - Bounded movement with screen edge clamping
- **Visual Effects** - Particle effects, hit flashes, explosions

## 🎯 How to Play

### Controls

- **WASD** or **Arrow Keys** - Move your ship
- **Space** - Fire weapons (auto-fire enabled)
- **ESC** - Pause game

### Gameplay Tips

1. **Stay Mobile** - Keep moving to dodge enemy fire
2. **Build Combos** - Destroy enemies quickly without getting hit to increase your score multiplier
3. **Collect Power-Ups** - Look for power-ups dropped by enemies (15% chance)
4. **Use Invincibility** - After taking damage, you have 2 seconds of invincibility - use it wisely
5. **Watch Enemy Patterns** - Each enemy type has different movement patterns:
   - **Basic** (Red): Moves straight down
   - **Fast** (Yellow): Zigzags across the screen
   - **Tank** (Purple): Circular pattern and shoots at you

## 🏗️ Architecture

This example demonstrates the integration of multiple MilitiaForge2D components:

### Components Used

1. **BoundedMovement** - Player movement with screen boundaries
2. **HealthComponent** - Health system with invincibility frames
3. **InputComponent** - Centralized input handling
4. **ScoreComponent** - Score tracking with combo system
5. **Hurtbox/Hitbox** - Damage collision detection
6. **ParticleEffectComponent** - Visual effects (prepared for expansion)

### Project Structure

```
space_shooter/
├── scripts/
│   ├── player_controller.gd      # Player ship controller
│   ├── enemy_base.gd              # Base enemy class
│   ├── wave_manager.gd            # Wave spawning system
│   ├── game_controller.gd         # Main game controller
│   ├── projectile.gd              # Projectile behavior
│   ├── simple_weapon.gd           # Weapon firing system
│   └── space_background.gd        # Parallax starfield
├── scenes/
│   ├── main_game.tscn             # Main game scene
│   └── projectile.tscn            # Projectile scene
├── ui/
│   └── game_hud.gd                # HUD overlay
└── README.md
```

## 🎨 Code Highlights

### Player Setup (player_controller.gd:30-106)

Shows how to integrate multiple components on a single entity:

```gdscript
# Create ComponentHost
host = ComponentHost.new()

# Add movement
movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
host.add_component(movement)

# Add health
health = HealthComponent.new()
health.invincibility_enabled = true
host.add_component(health)

# Add input
input_component = InputComponent.new()
host.add_component(input_component)

# Components work together automatically!
```

### Enemy AI (enemy_base.gd:225-249)

Demonstrates different movement patterns:

```gdscript
match movement_pattern:
	MovementPattern.STRAIGHT_DOWN:
		direction = Vector2.DOWN
	MovementPattern.ZIGZAG:
		direction = Vector2.DOWN
		direction.x = sin(movement_time * 3.0)
	MovementPattern.CIRCULAR:
		direction.x = cos(movement_time * 2.0)
		direction.y = 0.5 + sin(movement_time * 2.0) * 0.5
```

### Wave System (wave_manager.gd:31-92)

Data-driven wave configuration:

```gdscript
var wave_definitions: Array[Dictionary] = [
	{
		"enemies": [
			{"type": "Basic", "count": 5, "health": 20, "speed": 100, "score": 100},
		],
		"spawn_delay": 1.0
	},
	# More waves...
]
```

## 🔧 Customization

### Adding New Enemy Types

1. Modify `enemy_base.gd:23` to add new `MovementPattern`
2. Implement pattern in `_update_movement()` (enemy_base.gd:225)
3. Update `_setup_visuals()` (enemy_base.gd:167) for different colors
4. Add to wave definitions in `wave_manager.gd`

### Adjusting Difficulty

Edit wave definitions in `wave_manager.gd:31-92`:
- Increase `count` for more enemies
- Reduce `spawn_delay` for faster spawning
- Increase `health` for tougher enemies
- Increase `speed` for faster movement

### Adding Power-Ups

Currently power-ups are triggered at a 15% chance (enemy_base.gd:287). To implement visual power-ups:

1. Create a `PowerUpComponent` scene
2. Use `PowerUpComponent` from MilitiaForge2D
3. Connect to player's `power_up_weapon()` and `power_up_shield()` methods

## 📊 MilitiaForge2D Benefits

This example demonstrates several benefits of the component-based architecture:

1. **Reusability** - Same components work for player and enemies
2. **Modularity** - Easy to add/remove features by adding/removing components
3. **Maintainability** - Clear separation of concerns
4. **Extensibility** - New features can be added without modifying existing code
5. **Testability** - Components can be tested independently

## 🚀 Running the Game

1. Open the MilitiaForge2D project in Godot 4.x
2. Navigate to `examples/space_shooter/scenes/main_game.tscn`
3. Press **F6** to run the scene or **F5** to run the project

## 🎓 Learning Objectives

By studying this example, you'll learn:

- ✅ How to integrate multiple components on a single entity
- ✅ Component communication through signals and references
- ✅ Data-driven design with wave configurations
- ✅ Game state management
- ✅ UI integration with gameplay systems
- ✅ Collision layer setup for different teams
- ✅ Object spawning and management

## 📝 Known Limitations

This is a demonstrative example with some simplified systems:

- **Visual Assets** - Uses colored rectangles instead of sprites
- **Audio** - Audio system not fully implemented
- **Particle Effects** - ParticleEffectComponent integrated but effects not fully configured
- **Power-Up Visuals** - Power-ups trigger effects but don't spawn visual pickups
- **Save System** - High score saving is basic

These are intentionally simple to keep focus on the framework architecture. A production game would expand these systems.

## 🤝 Contributing

Feel free to extend this example! Some ideas:

- Add sprite assets
- Implement sound effects and music
- Create boss enemies
- Add different weapon types
- Implement visual power-up pickups
- Add screen shake effects
- Create menu screens
- Add difficulty settings

## 📄 License

This example is part of the MilitiaForge2D framework and follows the same license.

---

**Happy coding!** 🚀⚔️

For more information about MilitiaForge2D, see the [main README](../../README.md) and [documentation](../../docs/README.md).
