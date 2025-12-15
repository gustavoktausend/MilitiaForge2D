# Changelog

All notable changes to MilitiaForge2D will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-13

### Added - Foundation Phase ✅

#### Core System
- `Component` base class with full lifecycle support
  - `initialize()`, `component_ready()`, `component_process()`, `component_physics_process()`, `cleanup()`
  - Enable/disable functionality
  - Component state management
  - Signal emission for lifecycle events
  - Helper methods for sibling component access

- `ComponentHost` manager class
  - Component registration and initialization
  - Automatic component discovery from children
  - Component lookup by type (single and multiple)
  - Lifecycle coordination (process/physics_process routing)
  - Component add/remove at runtime
  - Enable/disable all components
  - Debug utilities

#### Testing Infrastructure
- `TestComponent` for system validation
- `component_foundation_test.tscn` - Interactive test scene
- Test controller with keyboard controls
- Visual UI for test feedback

#### Documentation
- `README.md` - Project overview
- `SOLID_PRINCIPLES.md` - Architecture principles
- `COMPONENT_CREATION.md` - Component development guide
- `component_foundation.md` - Complete system documentation
- `QUICK_REFERENCE.md` - Developer quick reference

#### Project Structure
- Complete folder hierarchy
- Godot 4.x project configuration
- `.gitignore` for version control
- Project icon (placeholder)

### Design Decisions

- **Component as Node**: Components extend Node for editor visibility and debugging
- **Host-managed lifecycle**: ComponentHost controls all lifecycle aspects
- **Signal-based communication**: Components communicate via signals for loose coupling
- **Type-based lookup**: Components stored in dictionaries by class name for O(1) access
- **Optional process methods**: Only override process methods when needed for performance

### Next Steps

- Implement first real component (HealthComponent suggested)
- Create more complex component examples
- Establish component patterns library

---

## [0.7.0] - 2024-12-13

### Added - Optional Components (Polish & Quality of Life) ✅

#### Environment Components
- `ScrollComponent` - Background scrolling system
  - Multi-layer parallax scrolling
  - Auto-scrolling with configurable speed and direction
  - Seamless looping
  - Speed modulation over time
  - Support for vertical/horizontal/custom directions
  - Perfect for side-scrollers and vertical shooters

#### Progression Components
- `PowerUpComponent` - Collectible power-ups system
  - 6 power-up types (health, ammo, weapon, speed, shield, score)
  - Temporary vs permanent effects
  - Stacking system
  - Magnetic attraction
  - Lifetime and expiration
  - Auto-collection
  - Visual effects (floating, blinking)

- `ScoreComponent` - Score and progression system
  - Score accumulation with multipliers
  - Combo system with decay
  - High score tracking (persistent)
  - Rank/grade system (F to SSS)
  - Milestones and achievements
  - Score events

#### Effects Components
- `ParticleEffectComponent` - Visual effects system
  - 8 effect presets (explosion, hit, trail, sparkle, smoke, fire, heal, powerup)
  - Trigger-based activation
  - One-shot or continuous effects
  - Object pooling for performance
  - Custom particle parameters
  - Integration with health/damage components

#### Audio Components
- `AudioComponent` - Sound and music system
  - Sound effect playback with pooling
  - Music management with crossfading
  - Volume control per category
  - Spatial audio support
  - Trigger-based sounds
  - Randomization (pitch, volume)
  - Audio ducking

### Design Decisions
- **Component Organization**: Separated into logical folders (environment, progression, effects, audio)
- **Generic Design**: All components are game-agnostic and reusable
- **Integration**: Components integrate seamlessly with existing systems
- **Performance**: Object pooling for particles and audio
- **Flexibility**: Extensive configuration options via exports

## [0.6.0] - 2024-12-13

### Added - BoundedMovement Component ✅

#### Core System
- `BoundedMovement` - Movement with boundary restrictions
  - Extends MovementComponent
  - Multiple boundary modes (CLAMP, BOUNCE, WRAP, DESTROY)
  - Auto viewport bounds detection
  - Custom bounds support
  - Configurable margins
  - Camera following for scrolling games
  - Boundary collision signals
  - Perfect for vertical shooters and arcade games

#### Testing Infrastructure
- `bounded_movement_test.tscn` - Interactive test scene
- `player_bounded_controller.gd` - Player controller example
- Demo entities showing different modes
  - Bouncing entities (BOUNCE mode)
  - Wrapping entity (WRAP mode)
  - Player with CLAMP mode
- Boundary visualization
- Live mode switching

#### Documentation
- Updated `movement.md` with BoundedMovement
- Updated `QUICK_REFERENCE_MOVEMENT.md`
- Usage examples for all boundary modes

### Design Decisions
- **Four boundary modes**: CLAMP (player), BOUNCE (enemies), WRAP (asteroids), DESTROY (projectiles)
- **Auto-detection**: Viewport bounds calculated automatically
- **Camera support**: Bounds follow camera for scrolling
- **Flexible margins**: Configurable offset from edges

## [0.5.0] - 2024-12-13

### Added - Input Component System ✅

#### Core System
- `InputComponent` - Centralized input management
  - Action-based input mapping
  - Multiple key bindings per action
  - Input buffering for combo systems (configurable frames)
  - Context stacking (gameplay/menu/cutscene)
  - Deadzone support for analog inputs
  - Easy rebinding system
  - Enable/disable functionality
  - Signal-based event system
  
- `InputAction` - Input action representation
  - Multiple key support
  - Edge detection (just_pressed/just_released)
  - Analog strength support
  - State tracking

#### Testing Infrastructure
- `input_test.tscn` - Interactive test scene
- `player_input_controller.gd` - Input integration example
- Real-time action display
- Context switching demonstration
- Rebinding live test
- Action log visualization

#### Documentation
- `input.md` - Complete system documentation
- `QUICK_REFERENCE_INPUT.md` - Quick reference guide
- Integration examples

### Design Decisions
- **Action-based**: Decouple input from keys
- **Buffer system**: Enable combo mechanics
- **Context stacking**: Different input states
- **Multi-binding**: Support keyboard + gamepad simultaneously
- **Signal events**: Centralized input notifications

## [0.4.0] - 2024-12-13

### Added - Health Component System ✅

#### Core System
- `HealthComponent` - Complete health management
  - Configurable max health and starting health
  - Damage and healing systems
  - Invincibility frames (i-frames) with duration control
  - Optional health regeneration with delay
  - Critical health detection and signaling
  - Death and revival system
  - Comprehensive signal emissions
  - Debug information export
  
- `Hurtbox` - Damage receiving area
  - Automatic HealthComponent integration
  - Hit flash visual feedback
  - Enable/disable functionality
  - Collision-based damage detection
  
- `Hitbox` - Damage dealing area
  - Configurable damage amount
  - Hit-once-per-target option
  - One-shot or continuous damage
  - Optional knockback system
  - Lifetime and activation delay
  - Auto-deactivation support

#### Testing Infrastructure
- `health_test.tscn` - Interactive test scene
- `player_health_controller.gd` - Player with health
- `enemy_wanderer.gd` - Enemy AI for testing
- Visual health bar and stats
- Manual damage/heal controls
- Multiple test enemies

#### Documentation
- `health.md` - Complete system documentation
- `QUICK_REFERENCE_HEALTH.md` - Quick reference guide
- Integration examples with other components

### Design Decisions
- **Invincibility frames**: Prevent damage spam
- **Regeneration optional**: Disabled by default
- **Hitbox/Hurtbox pattern**: Area2D-based collision detection
- **Signal-heavy**: Events for all health changes
- **Knockback integration**: Optional MovementComponent integration

## [0.3.0] - 2024-12-13

### Added - Movement Component System ✅

#### Core System
- `MovementComponent` base class
  - Physics body integration (CharacterBody2D/RigidBody2D)
  - Velocity management with acceleration/friction
  - Movement state tracking
  - Signal-based event system
  - Helper methods for smooth movement
  - Direction handling with normalization
  
- `TopDownMovement` component
  - 8-directional movement with smooth acceleration
  - Diagonal normalization (prevents faster diagonal movement)
  - Sprint system with configurable multipliers
  - Input deadzone support
  - Auto-sprint management
  - State tracking (idle/moving/sprinting)

#### Testing Infrastructure
- `topdown_movement_test.tscn` - Interactive test scene
- `player_movement_controller.gd` - Input integration example
- Visual player with direction indicator
- Real-time movement stats display
- Camera follow system
- Live parameter adjustment

#### Documentation
- `movement.md` - Complete movement system documentation
  - Architecture overview
  - TopDownMovement guide
  - Usage examples
  - Common patterns
  - Advanced techniques
- `QUICK_REFERENCE_MOVEMENT.md` - Quick reference guide

### Design Decisions
- **MovementComponent as base**: Abstract class for all movement types
- **Physics body integration**: Automatic detection of CharacterBody2D/RigidBody2D
- **Signal-based events**: Movement events communicated via signals
- **Separate sprint system**: Optional feature with multipliers
- **Smooth acceleration**: Move_toward for smooth velocity changes

## [0.2.0] - 2024-12-13

### Added - State Machine Component ✅

#### Core System
- `State` base class with full lifecycle support
  - `enter()`, `update()`, `physics_update()`, `exit()`
  - State transition requests via return values or signals
  - Time tracking (`time_in_state`)
  - Helper methods for state communication
  - Conditional transition support (`can_transition_to()`)
  - Debug information export

- `StateMachine` component
  - Automatic state discovery from children
  - State transition management with validation
  - Manual and automatic transitions
  - State history tracking (optional)
  - Force state capability (bypass conditions)
  - Debug mode with transition logging
  - Self-transition control
  - Signal-based event system

#### Example States
- `IdleState` - Timer-based state example
- `WalkState` - Movement state with duration
- `RunState` - Fast movement with stamina

#### Testing Infrastructure
- `state_machine_test.tscn` - Interactive test scene
- Auto/manual mode toggle
- Visual state information display
- Real-time transition tracking
- State history viewer
- Keyboard controls for testing

#### Documentation
- `state_machine.md` - Complete component documentation
  - Architecture overview
  - Usage examples
  - Common patterns
  - Advanced techniques
  - Performance considerations
  - SOLID compliance validation

### Design Decisions
- **State as Node**: States are nodes for editor visibility
- **Return-based transitions**: States return next state name from update methods
- **Optional history**: Configurable state history tracking
- **Signal communication**: States communicate via signals
- **Conditional transitions**: States can validate transitions via `can_transition_to()`

## [Unreleased]

### Planned Components
- HealthComponent (health/damage system)
- MovementComponent (platformer/top-down/grid)
- InventoryComponent (item management)

### Planned Features
- Component dependency validation
- Component serialization/deserialization
- Event bus system for global communication
- Component pooling for performance

---

*Legend*:
- ✅ Complete
- 🚧 In Progress
- 📋 Planned
