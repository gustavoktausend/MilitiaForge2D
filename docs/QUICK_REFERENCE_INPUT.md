# Quick Reference - Input System

## Setup

```gdscript
# Add component
var input_comp = InputComponent.new()
host.add_component(input_comp)

# Register actions
input_comp.add_action("jump", [KEY_SPACE, JOY_BUTTON_A])
input_comp.add_action("move_left", [KEY_A, KEY_LEFT])
input_comp.add_action("attack", [KEY_J])
```

## Query Input

```gdscript
# Check if pressed
if input_comp.is_action_pressed("jump"):
    pass

# Just pressed (single frame)
if input_comp.is_action_just_pressed("attack"):
    pass

# Just released
if input_comp.is_action_just_released("jump"):
    pass

# Get strength (0.0 to 1.0)
var strength = input_comp.get_action_strength("jump")
```

## Vectors & Axes

```gdscript
# Get 2D vector
var move_dir = input_comp.get_vector(
    "move_left", "move_right",
    "move_up", "move_down"
)

# Get axis (-1.0 to 1.0)
var horizontal = input_comp.get_axis("move_left", "move_right")
```

## Rebinding

```gdscript
# Clear bindings
input_comp.clear_action_keys("jump")

# Bind new key
input_comp.bind_key("jump", KEY_K)

# Unbind specific key
input_comp.unbind_key("jump", KEY_SPACE)
```

## Input Buffering

```gdscript
# Check if action was in buffer
if input_comp.was_action_buffered("jump", 5):
    # Jump was pressed in last 5 frames
    pass

# Clear buffer
input_comp.clear_buffer()
```

## Context Management

```gdscript
# Push new context
input_comp.push_context("menu")

# Pop context
input_comp.pop_context()

# Disable actions in context
input_comp.disable_actions(["move_left", "move_right"])

# Re-enable
input_comp.enable_actions(["move_left", "move_right"])
```

## Enable/Disable

```gdscript
# Disable all input
input_comp.disable_input()

# Enable input
input_comp.enable_input()
```

## Signals

```gdscript
# Connect to signals
input_comp.action_pressed.connect(func(action): 
    print("Pressed: " + action)
)

input_comp.action_released.connect(func(action):
    print("Released: " + action)
)

input_comp.context_changed.connect(func(context):
    print("Context: " + context)
)
```

## Common Patterns

### Movement

```gdscript
func _physics_process(_delta):
    var dir = input_comp.get_vector(
        "left", "right", "up", "down"
    )
    movement.set_direction(dir)
```

### Actions with State

```gdscript
# Sprint while held
if input_comp.is_action_pressed("sprint"):
    movement.start_sprint()
else:
    movement.stop_sprint()
```

### One-Shot Actions

```gdscript
# Jump only once per press
if input_comp.is_action_just_pressed("jump"):
    player.jump()
```

### Buffered Input

```gdscript
# Check buffer for tight timing
if input_comp.was_action_buffered("jump", 3):
    if player.can_jump():
        player.jump()
```

## Configuration

```gdscript
# Settings
input_comp.input_enabled = true
input_comp.analog_deadzone = 0.2
input_comp.buffer_enabled = true
input_comp.buffer_size = 5
input_comp.current_context = "gameplay"
input_comp.debug_input = false
```

## Tips

- ✅ Register all actions in _ready()
- ✅ Use get_vector() for movement
- ✅ Use just_pressed for single actions
- ✅ Enable buffering for combos
- ✅ Use contexts for different game states
- ❌ Don't use Input directly (bypasses component)
- ❌ Don't forget to register actions before use
