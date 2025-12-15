# Input Component System

**Status**: ✅ Complete  
**Version**: 1.0.0  
**Last Updated**: 2024-12-13

## 📋 Overview

The Input Component System provides centralized input management with support for multiple input schemes, input buffering, rebinding, and context management. It decouples input handling from game logic, making it easy to support different control schemes and devices.

## 🎯 Use Cases

- Player input management
- Support for keyboard + gamepad + touch
- Input rebinding/remapping
- Context-based input (gameplay, menu, cutscene)
- Combo systems with input buffering
- Accessibility features
- Local multiplayer (different input per player)

## 🏗️ Architecture

### Core Classes

#### `InputComponent` (input_component.gd)

Main input management component.

**Features**:
- Action-based input mapping
- Multiple key bindings per action
- Input buffering for combos
- Context stacking
- Deadzone support
- Easy rebinding
- Signal-based events

**Key Methods**:
```gdscript
# Action management
add_action(action_name: String, keys: Array[int]) -> void
bind_key(action_name: String, key: int) -> void
unbind_key(action_name: String, key: int) -> void

# Input queries
is_action_pressed(action_name: String) -> bool
is_action_just_pressed(action_name: String) -> bool
is_action_just_released(action_name: String) -> bool
get_action_strength(action_name: String) -> float
get_vector(neg_x, pos_x, neg_y, pos_y) -> Vector2
get_axis(negative, positive) -> float

# Buffer
was_action_buffered(action_name: String, frames_back: int) -> bool
clear_buffer() -> void

# Context
push_context(context_name: String) -> void
pop_context() -> void
disable_actions(actions: Array[String]) -> void
```

**Signals**:
```gdscript
action_pressed(action_name)
action_released(action_name)
context_changed(new_context)
```

**Exports**:
- `input_enabled: bool` - Enable/disable input
- `analog_deadzone: float` - Deadzone for analog (0.0-1.0)
- `buffer_enabled: bool` - Enable input buffering
- `buffer_size: int` - Frames to buffer
- `current_context: String` - Active context

---

#### `InputAction` (input_action.gd)

Represents a single input action with multiple key bindings.

**Properties**:
- `action_name: String` - Name of the action
- `keys: Array[int]` - Bound keys/buttons
- `just_pressed: bool` - Edge detection
- `just_released: bool` - Edge detection
- `is_pressed: bool` - Current state
- `strength: float` - Analog strength (0.0-1.0)

---

## 💡 Usage Examples

### Basic Setup

```gdscript
# Add InputComponent
var input_comp = InputComponent.new()
host.add_component(input_comp)

# Register actions
input_comp.add_action("move_left", [KEY_A, KEY_LEFT])
input_comp.add_action("move_right", [KEY_D, KEY_RIGHT])
input_comp.add_action("jump", [KEY_SPACE, JOY_BUTTON_A])
input_comp.add_action("attack", [KEY_J, JOY_BUTTON_X])
```

### Querying Input

```gdscript
# Check if pressed
if input_comp.is_action_pressed("jump"):
    player.jump()

# Check for just pressed (single frame)
if input_comp.is_action_just_pressed("attack"):
    player.attack()

# Get movement vector
var move_dir = input_comp.get_vector(
    "move_left", "move_right",
    "move_up", "move_down"
)
movement.set_direction(move_dir)

# Get axis value
var horizontal = input_comp.get_axis("move_left", "move_right")
```

### Input Buffering

```gdscript
# Useful for combos and tight timing
if input_comp.was_action_buffered("jump", 3):
    # Jump was pressed in last 3 frames
    player.perform_buffered_jump()
```

### Context Management

```gdscript
# Push menu context
input_comp.push_context("menu")
# Now in menu context

# Pop back to previous
input_comp.pop_context()
# Back to gameplay
```

### Rebinding

```gdscript
# Clear old bindings
input_comp.clear_action_keys("jump")

# Bind new key
input_comp.bind_key("jump", KEY_K)

# Or unbind specific key
input_comp.unbind_key("jump", KEY_SPACE)
```

### With Movement Component

```gdscript
func _physics_process(_delta):
    var input_dir = input_comp.get_vector(
        "move_left", "move_right",
        "move_up", "move_down"
    )
    
    movement.set_input_direction(input_dir)
    
    if input_comp.is_action_pressed("sprint"):
        movement.start_sprint()
```

### Signal-Based

```gdscript
func _ready():
    input_comp.action_pressed.connect(_on_action_pressed)
    input_comp.action_released.connect(_on_action_released)

func _on_action_pressed(action_name: String):
    match action_name:
        "jump":
            _play_jump_sound()
        "attack":
            _play_attack_sound()
```

---

## 🧪 Testing

Test scene: `sandbox/test_scenes/input_test.tscn`

### Test Features

- **Real-time Action Display**: Shows active actions
- **Action Log**: Recent presses/releases
- **Context Display**: Current input context
- **Buffer Status**: Visualization of buffering
- **Rebinding Test**: Live rebinding demonstration

### Test Controls

- **[WASD]/[Arrows]** - Move
- **[Shift]** - Sprint
- **[Space]** - Jump
- **[E]** - Interact
- **[J]** - Attack
- **[ESC]** - Pause
- **[1]** - Toggle input enable/disable
- **[2]** - Push menu context
- **[3]** - Pop context
- **[4]** - Toggle buffer
- **[R]** - Rebind jump to 'K'
- **[T]** - Reset jump to Space
- **[D]** - Debug print
- **[Q]** - Quit

### What to Test

1. **Basic Input**: Press buttons, see them register
2. **Movement**: WASD movement with sprint
3. **Context Switching**: Push/pop contexts
4. **Rebinding**: Change key bindings live
5. **Buffering**: Test input buffer
6. **Deadzone**: Analog deadzone (if gamepad)

---

## ✅ SOLID Compliance

- ✅ **SRP**: InputComponent handles input only
- ✅ **OCP**: Extend for custom input schemes
- ✅ **LSP**: Works as Component
- ✅ **ISP**: Optional features (buffer, contexts)
- ✅ **DIP**: Depends on Component abstraction

---

## 🎨 Design Patterns

### Command Pattern
Actions decouple input from execution.

### Observer Pattern
Signals notify listeners of input events.

### State Pattern
Contexts change input behavior.

---

## 🔍 Common Patterns

### Combo System

```gdscript
# Check for combo in buffer
if input_comp.was_action_buffered("attack", 10):
    if input_comp.is_action_just_pressed("special"):
        perform_combo_attack()
```

### Context-Based Disable

```gdscript
# Disable movement during cutscene
input_comp.push_context("cutscene")
input_comp.disable_actions(["move_left", "move_right", "move_up", "move_down"])
```

### Multiple Players

```gdscript
# Player 1
var p1_input = InputComponent.new()
p1_input.add_action("jump", [KEY_W])

# Player 2
var p2_input = InputComponent.new()
p2_input.add_action("jump", [KEY_UP])
```

---

## 🚨 Common Pitfalls

### ❌ Don't: Poll Input.is_action_pressed directly

```gdscript
# Wrong - bypasses InputComponent
if Input.is_action_pressed("jump"):
    pass
```

### ✅ Do: Use InputComponent

```gdscript
# Correct
if input_comp.is_action_pressed("jump"):
    pass
```

### ❌ Don't: Forget to setup actions

```gdscript
# Wrong - action not registered
if input_comp.is_action_pressed("undefined_action"):
    pass  # Returns false, no error
```

### ✅ Do: Register all actions

```gdscript
# Correct
input_comp.add_action("jump", [KEY_SPACE])
if input_comp.is_action_pressed("jump"):
    pass
```

---

## 📚 Related Documentation

- [Component Foundation](component_foundation.md)
- [Movement System](movement.md)
- [State Machine](state_machine.md)

---

## 🎯 Next Steps

With InputComponent complete:

1. Centralize all input through InputComponent
2. Create input configuration UI
3. Support gamepad/touch schemes
4. Build combo systems with buffering
5. Implement accessibility options

The Input System is production-ready! 🎮
