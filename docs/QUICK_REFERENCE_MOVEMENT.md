# Quick Reference - Movement Components

## TopDownMovement

### Basic Setup

```gdscript
# On CharacterBody2D or with CharacterBody2D child
var movement = TopDownMovement.new()
movement.max_speed = 200.0
movement.acceleration = 1000.0
movement.friction = 800.0
host.add_component(movement)
```

### Setting Direction

```gdscript
# From input
var input_dir = Input.get_vector("left", "right", "up", "down")
movement.set_input_direction(input_dir)

# Manually
movement.set_direction(Vector2.RIGHT)  # Move right
movement.set_direction(Vector2(1, 1))  # Move diagonally
```

### Sprint System

```gdscript
# Start sprint
movement.start_sprint()

# Stop sprint
movement.stop_sprint()

# Toggle
movement.toggle_sprint()

# Check state
if movement.is_sprinting():
    print("Sprinting!")
```

### Getting Movement Info

```gdscript
# Velocity
var vel = movement.get_velocity()  # Vector2

# Speed (magnitude)
var speed = movement.get_speed()  # float

# Check if moving
if movement.is_moving():
    print("Moving!")

# Direction
var dir = movement.direction  # Vector2 (normalized)
```

### Control

```gdscript
# Stop completely
movement.stop()

# Enable/disable
movement.enable_movement()
movement.disable_movement()
```

## Common Patterns

### Player Input

```gdscript
extends CharacterBody2D

var movement: TopDownMovement

func _ready():
    movement = $ComponentHost.get_component("TopDownMovement")

func _physics_process(_delta):
    var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    movement.set_input_direction(input)
    
    if Input.is_action_pressed("sprint"):
        movement.start_sprint()
    else:
        movement.stop_sprint()
```

### AI Movement

```gdscript
var movement: TopDownMovement

func move_to_target(target_pos: Vector2):
    var dir = (target_pos - global_position).normalized()
    movement.set_direction(dir)
```

### With Animations

```gdscript
func _ready():
    movement.movement_started.connect(_on_move_start)
    movement.movement_stopped.connect(_on_move_stop)
    movement.direction_changed.connect(_on_dir_change)

func _on_move_start(direction: Vector2):
    anim_player.play("walk")

func _on_move_stop():
    anim_player.play("idle")
```

## Key Properties

```gdscript
# Speed
movement.max_speed = 200.0
movement.acceleration = 1000.0
movement.friction = 800.0

# TopDown specific
movement.normalize_diagonal = true
movement.input_deadzone = 0.1

# Sprint
movement.sprint_enabled = true
movement.sprint_multiplier = 1.5
movement.sprint_acceleration_multiplier = 1.2

# State
movement.movement_enabled = true
movement.debug_movement = false
```

## Signals

```gdscript
# Base signals
movement.movement_started.connect(func(dir): pass)
movement.movement_stopped.connect(func(): pass)
movement.velocity_changed.connect(func(vel): pass)
movement.direction_changed.connect(func(dir): pass)

# TopDown signals
movement.sprint_started.connect(func(): pass)
movement.sprint_ended.connect(func(): pass)
```

## Tips

- ✅ Set direction every frame for smooth movement
- ✅ Cache movement component reference in _ready()
- ✅ Use signals for animations and sound effects
- ✅ Normalize diagonal prevents faster diagonal movement
- ✅ Adjust friction for different surface feels
- ❌ Don't manually set velocity on physics body
- ❌ Don't forget physics body in hierarchy

---

## BoundedMovement

### Basic Setup

```gdscript
# On CharacterBody2D with boundary restriction
var movement = BoundedMovement.new()
movement.max_speed = 300.0
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
movement.boundary_margin = Vector2(16, 16)
host.add_component(movement)
```

### Boundary Modes

```gdscript
# CLAMP - Stop at edge (player ship)
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP

# BOUNCE - Bounce off edge (enemies)
movement.boundary_mode = BoundedMovement.BoundaryMode.BOUNCE
movement.bounce_factor = 0.8

# WRAP - Wrap to other side (Asteroids)
movement.boundary_mode = BoundedMovement.BoundaryMode.WRAP

# DESTROY - Destroy at edge (projectiles)
movement.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
```

### Bounds Configuration

```gdscript
# Use viewport bounds (auto)
movement.use_viewport_bounds = true

# Custom bounds
movement.use_viewport_bounds = false
movement.custom_bounds = Rect2(0, 0, 1280, 720)

# Adjust margin
movement.boundary_margin = Vector2(32, 32)  # Pixels from edge

# Follow camera
movement.follow_camera = true
```

### Queries

```gdscript
# Get current bounds
var bounds = movement.get_current_bounds()

# Check if within bounds
if movement.is_within_bounds(position):
    pass

# Distance to nearest boundary
var distance = movement.get_distance_to_boundary(position)

# Force recalculation
movement.recalculate_bounds()
```

### Signals

```gdscript
# Boundary touched
movement.boundary_touched.connect(func(edge, pos):
    print("Hit edge: ", edge)
)

# Destroyed by boundary
movement.destroyed_by_boundary.connect(func(edge):
    queue_free()
)
```

## Common Patterns - BoundedMovement

### Vertical Shooter Player

```gdscript
extends CharacterBody2D

var movement: BoundedMovement

func _ready():
    movement = $ComponentHost.get_component("BoundedMovement")
    movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
    movement.boundary_margin = Vector2(16, 16)

func _physics_process(_delta):
    var input = Input.get_vector("left", "right", "up", "down")
    movement.set_direction(input)
```

### Bouncing Enemy

```gdscript
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.BOUNCE
movement.bounce_factor = 0.9
movement.velocity = Vector2(200, 150)  # Initial direction
```

### Auto-Destroy Projectile

```gdscript
var movement = BoundedMovement.new()
movement.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
movement.velocity = direction * 500
movement.destroyed_by_boundary.connect(func(_edge): queue_free())
```

## BoundedMovement Tips

- ✅ Use CLAMP for player ships
- ✅ Use BOUNCE for enemies and power-ups
- ✅ Use DESTROY for projectiles
- ✅ Use WRAP for Asteroids-style games
- ✅ Adjust margin to keep sprites fully on screen
- ✅ Connect to boundary_touched for visual feedback
- ❌ Don't forget to set boundary_mode
- ❌ DESTROY mode will queue_free the host!
