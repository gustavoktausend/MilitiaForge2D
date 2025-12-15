# Movement Component System

**Status**: ✅ TopDownMovement Complete  
**Version**: 1.0.0  
**Last Updated**: 2024-12-13

## 📋 Overview

The Movement Component System provides flexible, reusable movement behaviors for 2D games. Components handle velocity calculation, physics integration, and movement state management.

## 🎯 Movement Types

### Implemented
- ✅ **TopDownMovement** - 8-directional free movement (RPGs, shooters)
- ✅ **BoundedMovement** - Movement with screen/area boundaries (vertical shooters, arcade games)

### Planned
- 📋 **PlatformerMovement** - Side-scrolling with jumping and gravity
- 📋 **GridMovement** - Tile-based discrete movement

## 🏗️ Architecture

### Core Classes

#### `MovementComponent` (movement_component.gd)

Abstract base class for all movement types.

**Responsibilities**:
- Physics body integration (CharacterBody2D/RigidBody2D)
- Velocity management
- Movement state tracking
- Signal emission for movement events
- Common movement utilities (friction, acceleration)

**Key Methods**:
```gdscript
set_direction(direction: Vector2) -> void
stop() -> void
enable_movement() -> void
disable_movement() -> void
get_velocity() -> Vector2
get_speed() -> float
is_moving() -> bool
```

**Signals**:
- `movement_started(direction)` - When movement begins
- `movement_stopped()` - When movement ends
- `velocity_changed(new_velocity)` - When velocity changes
- `direction_changed(new_direction)` - When direction changes

**Exports**:
- `max_speed: float` - Maximum movement speed
- `acceleration: float` - Acceleration rate
- `friction: float` - Deceleration/friction rate
- `movement_enabled: bool` - Enable/disable movement

---

#### `TopDownMovement` (topdown_movement.gd)

8-directional top-down movement implementation.

**Features**:
- Normalized diagonal movement (optional)
- Smooth acceleration/deceleration
- Sprint system with speed multiplier
- Input deadzone support
- Auto-sprint management

**Additional Methods**:
```gdscript
set_input_direction(input_vector: Vector2) -> void
start_sprint() -> void
stop_sprint() -> void
toggle_sprint() -> void
is_sprinting() -> bool
```

**Additional Signals**:
- `sprint_started()` - When sprint begins
- `sprint_ended()` - When sprint ends

**Additional Exports**:
- `normalize_diagonal: bool` - Normalize diagonal movement
- `input_deadzone: float` - Input deadzone (0.0 to 1.0)
- `sprint_enabled: bool` - Enable sprint feature
- `sprint_multiplier: float` - Sprint speed multiplier

---

#### `BoundedMovement` (bounded_movement.gd)

Movement with screen/area boundary restrictions. Perfect for vertical shooters and arcade games.

**Features**:
- Multiple boundary modes (clamp, bounce, wrap, destroy)
- Auto-detection of viewport bounds
- Custom boundary areas  
- Configurable margins
- Camera following support
- Boundary collision signals

**Key Methods**:
```gdscript
set_boundary_mode(mode: BoundaryMode) -> void
set_custom_bounds(bounds: Rect2) -> void
get_current_bounds() -> Rect2
is_within_bounds(pos: Vector2) -> bool
get_distance_to_boundary(pos: Vector2) -> float
recalculate_bounds() -> void
```

**Signals**:
```gdscript
boundary_touched(edge: BoundaryEdge, position: Vector2)
destroyed_by_boundary(edge: BoundaryEdge)
```

**Boundary Modes**:
- `CLAMP` - Stop at boundary (player ship in shooter)
- `BOUNCE` - Bounce off boundary (enemies, power-ups)
- `WRAP` - Wrap to opposite side (Asteroids-style)
- `DESTROY` - Destroy when leaving bounds (projectiles)

**Exports**:
- `boundary_mode: BoundaryMode` - Boundary behavior
- `use_viewport_bounds: bool` - Auto-use viewport
- `custom_bounds: Rect2` - Custom boundary area
- `boundary_margin: Vector2` - Margin from edges (pixels)
- `bounce_factor: float` - Bounce strength (0.0-1.0)
- `follow_camera: bool` - Follow camera for bounds calculation

---

## 🔄 Movement Lifecycle

```
1. Input/Direction Set
   ↓
2. _calculate_velocity() - Subclass implements movement logic
   ↓
3. _apply_velocity() - Apply to physics body
   ↓
4. _update_movement_state() - Detect start/stop, emit signals
```

---

## 💡 Usage Examples

### Basic Setup

```gdscript
# On a CharacterBody2D
var host = ComponentHost.new()
add_child(host)

var movement = TopDownMovement.new()
movement.max_speed = 200.0
movement.acceleration = 1000.0
movement.sprint_enabled = true
host.add_component(movement)
```

### Input Integration

```gdscript
# In player controller
extends CharacterBody2D

var movement: TopDownMovement

func _ready():
    movement = $ComponentHost.get_component("TopDownMovement")

func _physics_process(_delta):
    # Get input
    var input_dir = Input.get_vector("left", "right", "up", "down")
    
    # Set direction
    movement.set_input_direction(input_dir)
    
    # Handle sprint
    if Input.is_action_pressed("sprint"):
        movement.start_sprint()
    else:
        movement.stop_sprint()
```

### AI Movement

```gdscript
# In AI controller
var movement: TopDownMovement

func _physics_process(_delta):
    # Calculate direction to target
    var direction_to_target = (target_position - global_position).normalized()
    
    # Move towards target
    movement.set_direction(direction_to_target)
    
    # Sprint when far away
    if global_position.distance_to(target_position) > 200:
        movement.start_sprint()
    else:
        movement.stop_sprint()
```

### State Machine Integration

```gdscript
# In a movement state
class_name WalkState extends State

var movement: TopDownMovement

func enter(previous_state: State = null):
    super.enter(previous_state)
    movement = get_sibling_component("TopDownMovement")
    movement.stop_sprint()

func update(delta: float) -> String:
    # Get input and move
    var input_dir = _get_player_input()
    movement.set_input_direction(input_dir)
    
    # Transition to run if sprinting
    if Input.is_action_pressed("sprint"):
        return "Run"
    
    return ""
```

### BoundedMovement Usage

#### Vertical Shooter Player Ship
```gdscript
# Player ship in vertical shooter
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
movement.max_speed = 300.0
movement.boundary_margin = Vector2(16, 16)
host.add_component(movement)

# Connect to boundary signals
movement.boundary_touched.connect(_on_boundary_hit)

func _on_boundary_hit(edge, position):
    # Play boundary hit sound
    $AudioPlayer.play()
```

#### Bouncing Enemy
```gdscript
# Enemy that bounces off screen edges
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.BOUNCE
movement.bounce_factor = 0.9
movement.velocity = Vector2(200, 150)  # Initial velocity
host.add_component(movement)
```

#### Projectile Auto-Destroy
```gdscript
# Projectile that destroys when leaving screen
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
movement.max_speed = 500.0
movement.velocity = Vector2.UP * 500
host.add_component(movement)

movement.destroyed_by_boundary.connect(_on_projectile_destroy)

func _on_projectile_destroy(edge):
    # Projectile left screen, clean up
    queue_free()
```

#### Asteroids-Style Wrap
```gdscript
# Entity that wraps to opposite side
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.WRAP
movement.max_speed = 200.0
host.add_component(movement)
```

#### Custom Bounds Area
```gdscript
# Restrict movement to specific area
var movement = BoundedMovement.new()
movement.use_viewport_bounds = false
movement.custom_bounds = Rect2(100, 100, 800, 600)
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
host.add_component(movement)
```

---

## 💡 Usage Examples (continued)

### State Machine Integration (original)

### Signal-Based Responses

```gdscript
func _ready():
    movement = $ComponentHost.get_component("TopDownMovement")
    
    # Connect to movement signals
    movement.movement_started.connect(_on_movement_started)
    movement.movement_stopped.connect(_on_movement_stopped)
    movement.sprint_started.connect(_on_sprint_started)

func _on_movement_started(direction: Vector2):
    # Start walking animation
    animation_player.play("walk")

func _on_movement_stopped():
    # Play idle animation
    animation_player.play("idle")

func _on_sprint_started():
    # Play sprint animation
    animation_player.play("sprint")
    # Play sprint sound
    audio_player.play()
```

---

## 🧪 Testing

Test scene: `sandbox/test_scenes/topdown_movement_test.tscn`

### Test Features

- **Visual Player**: Blue square with direction indicator
- **Real-time Stats**: Velocity, speed, direction, state display
- **Sprint Indicator**: Yellow when sprinting
- **Camera Follow**: Smooth camera tracking
- **Parameter Tweaking**: Live adjustment of settings
- **Position Reset**: R key to reset position

### Test Controls

- **[WASD]** or **[Arrow Keys]** - Move in 8 directions
- **[Shift]** - Sprint (hold)
- **[1]** - Toggle diagonal normalization
- **[2]** - Increase max speed (+50)
- **[3]** - Decrease max speed (-50)
- **[D]** - Debug print movement info
- **[R]** - Reset position to center
- **[Q]** - Quit

### What to Test

1. **Basic Movement**: Move in all 8 directions
2. **Diagonal Speed**: With/without normalization (toggle with 1)
3. **Sprint**: Hold shift while moving
4. **Acceleration**: Feel the smooth acceleration
5. **Friction**: Release input and feel deceleration
6. **Speed Tweaking**: Adjust max_speed with 2/3

---

## ✅ SOLID Compliance

### Single Responsibility Principle (SRP)
- ✅ MovementComponent: Handles movement physics only
- ✅ TopDownMovement: Handles top-down movement logic only

### Open/Closed Principle (OCP)
- ✅ New movement types extend MovementComponent
- ✅ No modification of base class needed

### Liskov Substitution Principle (LSP)
- ✅ Any MovementComponent works in ComponentHost
- ✅ TopDownMovement can replace MovementComponent

### Interface Segregation Principle (ISP)
- ✅ Only implement _calculate_velocity() when needed
- ✅ Optional features (sprint) are separate

### Dependency Inversion Principle (DIP)
- ✅ Depends on Node2D (physics body abstraction)
- ✅ Works with CharacterBody2D or RigidBody2D

---

## 📊 Performance Considerations

### Memory
- Lightweight component (~200 bytes)
- Minimal state tracking
- No dynamic allocations in hot paths

### Processing
- Runs in `_physics_process()` only
- Efficient vector math
- No expensive operations per frame

### Best Practices
- Cache component reference in `_ready()`
- Use signals instead of polling movement state
- Disable component when not needed
- Consider using states for complex movement logic

---

## 🎨 Design Patterns

### Strategy Pattern
Different movement types (TopDown, Platformer, Grid) implement different strategies.

### Template Method
Base class provides movement template, subclasses fill in velocity calculation.

### Observer Pattern
Signals notify other systems of movement events.

---

## 🔍 Common Patterns

### Movement with Animations

```gdscript
var movement: TopDownMovement
var animation_tree: AnimationTree

func _ready():
    movement.movement_started.connect(_on_move_start)
    movement.direction_changed.connect(_on_direction_change)

func _on_move_start(direction: Vector2):
    animation_tree.set("parameters/idle_to_walk/transition_request", "walk")

func _on_direction_change(direction: Vector2):
    # Update animation blend position
    animation_tree.set("parameters/walk/blend_position", direction)
```

### Movement with Stamina

```gdscript
var movement: TopDownMovement
var stamina: float = 100.0

func _physics_process(delta):
    if movement.is_sprinting():
        stamina -= 20 * delta
        if stamina <= 0:
            movement.stop_sprint()
    else:
        stamina = min(100, stamina + 10 * delta)
```

### Knockback/Force Application

```gdscript
func apply_knockback(direction: Vector2, force: float):
    # Temporarily disable movement
    movement.disable_movement()
    
    # Apply knockback velocity
    movement.velocity = direction.normalized() * force
    
    # Re-enable after delay
    await get_tree().create_timer(0.3).timeout
    movement.enable_movement()
```

### Speed Modifiers (Buffs/Debuffs)

```gdscript
var base_speed: float = 200.0
var speed_modifiers: Array[float] = []

func add_speed_modifier(multiplier: float):
    speed_modifiers.append(multiplier)
    _update_speed()

func _update_speed():
    var total_multiplier = 1.0
    for mod in speed_modifiers:
        total_multiplier *= mod
    
    movement.max_speed = base_speed * total_multiplier
```

---

## 🚨 Common Pitfalls

### ❌ Don't: Manually set velocity on physics body

```gdscript
# Wrong - bypasses movement component
character_body.velocity = Vector2(100, 0)
```

### ✅ Do: Use movement component methods

```gdscript
# Correct - uses movement system
movement.set_direction(Vector2.RIGHT)
```

### ❌ Don't: Forget to pass physics body

```gdscript
# Wrong - no CharacterBody2D in hierarchy
var host = Node2D.new()
host.add_component(TopDownMovement.new())
```

### ✅ Do: Ensure physics body exists

```gdscript
# Correct - CharacterBody2D is in hierarchy
var character = CharacterBody2D.new()
var host = ComponentHost.new()
character.add_child(host)
host.add_component(TopDownMovement.new())
```

---

## 🎓 Advanced Techniques

### Custom Movement Type

```gdscript
class_name CustomMovement extends MovementComponent

func _calculate_velocity(delta: float) -> void:
    # Implement your custom movement logic
    var target_velocity = direction * max_speed
    
    # Custom acceleration curve
    velocity = velocity.lerp(target_velocity, 0.1)
    
    # Custom speed limit
    _clamp_velocity()
```

### Movement Zones

```gdscript
# Different speeds in different areas
func _on_area_entered(area: Area2D):
    if area.is_in_group("water"):
        movement.max_speed = 100  # Slower in water
    elif area.is_in_group("ice"):
        movement.friction = 200   # Slippery ice

func _on_area_exited(area: Area2D):
    movement.max_speed = 200  # Reset to normal
    movement.friction = 800
```

### Dash/Blink Ability

```gdscript
func dash(dash_direction: Vector2):
    var dash_distance = 200
    var dash_duration = 0.2
    
    # Disable normal movement
    movement.disable_movement()
    
    # Calculate dash target
    var start_pos = global_position
    var target_pos = start_pos + dash_direction.normalized() * dash_distance
    
    # Tween to target
    var tween = create_tween()
    tween.tween_property(self, "global_position", target_pos, dash_duration)
    await tween.finished
    
    # Re-enable movement
    movement.enable_movement()
```

---

## 📚 Related Documentation

- [Component Foundation](component_foundation.md)
- [State Machine](state_machine.md)
- [SOLID Principles](../architecture/SOLID_PRINCIPLES.md)

---

## 🎯 Next Steps

With TopDownMovement complete:

1. Test different parameter combinations
2. Integrate with animations
3. Add sound effects on movement events
4. Combine with StateMachine for complex behaviors
5. Create AI behaviors using movement component

Coming next:
- PlatformerMovement (jumping, gravity, wall slide)
- GridMovement (tile-based, turn-based)

The TopDownMovement is production-ready and highly flexible! 🎮⚔️
