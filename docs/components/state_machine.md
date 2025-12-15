# State Machine Component

**Status**: ✅ Complete  
**Version**: 1.0.0  
**Last Updated**: 2024-12-13

## 📋 Overview

The StateMachine component provides a flexible, reusable state machine system for managing entity behaviors. It's perfect for AI, player controls, animations, UI flows, and any system that needs distinct behavioral states.

## 🎯 Use Cases

- **Player States**: idle, walking, running, jumping, attacking, dead
- **Enemy AI**: patrol, chase, attack, flee, idle
- **UI States**: menu, playing, paused, game_over
- **Animation States**: different animation sequences
- **Game Flow**: intro, gameplay, victory, defeat

## 🏗️ Architecture

### Core Classes

#### `State` (state.gd)

Base class for all states. Each state represents a distinct behavior.

**Key Methods**:
```gdscript
enter(previous_state: State) -> void       # Called when entering state
update(delta: float) -> String             # Per-frame logic, return next state or ""
physics_update(delta: float) -> String     # Physics logic, return next state or ""
exit(next_state: State) -> void            # Called when exiting state
```

**Properties**:
- `state_machine: StateMachine` - Reference to parent state machine
- `host: Node` - Reference to the entity this state controls
- `is_active: bool` - Whether this state is currently active
- `time_in_state: float` - Time spent in this state

---

#### `StateMachine` (state_machine.gd)

Component that manages state transitions and lifecycle.

**Key Methods**:
```gdscript
change_state(state_name: String) -> bool        # Change to a new state
force_state(state_name: String) -> bool         # Force state without checks
get_current_state() -> State                     # Get active state
get_current_state_name() -> String              # Get active state name
get_state(state_name: String) -> State          # Get specific state
```

**Exports**:
- `initial_state_name: String` - Starting state
- `track_history: bool` - Keep state transition history
- `debug_transitions: bool` - Print debug messages
- `allow_self_transitions: bool` - Allow transitioning to same state

**Signals**:
- `state_changed(from_state, to_state)` - When state changes
- `transition_blocked(from_state, to_state, reason)` - When transition is rejected

---

## 🔄 State Lifecycle

States follow a simple but powerful lifecycle:

```
┌─────────────────────────────────────┐
│  enter(previous_state)              │ ← Setup when entering
├─────────────────────────────────────┤
│  update(delta) → next_state_name    │ ← Per-frame logic
│  physics_update(delta) → next       │ ← Physics logic
├─────────────────────────────────────┤
│  exit(next_state)                   │ ← Cleanup when exiting
└─────────────────────────────────────┘
```

### Transition Flow

1. Current state's `update()` or `physics_update()` returns a state name
2. StateMachine validates the transition
3. Current state's `exit()` is called
4. New state's `enter()` is called
5. `state_changed` signal is emitted

---

## 💡 Usage Examples

### Basic Setup

```gdscript
# In your scene
var host = ComponentHost.new()
add_child(host)

# Create state machine
var state_machine = StateMachine.new()
state_machine.initial_state_name = "Idle"
state_machine.debug_transitions = true
host.add_component(state_machine)

# Add states as children
var idle = IdleState.new()
idle.name = "Idle"
state_machine.add_child(idle)

var walk = WalkState.new()
walk.name = "Walk"
state_machine.add_child(walk)
```

### Creating a Custom State

```gdscript
class_name AttackState extends State

@export var attack_damage: int = 10
@export var attack_duration: float = 0.5

var _target: Node = null

func enter(previous_state: State = null) -> void:
    super.enter(previous_state)
    
    # Start attack animation
    print("Starting attack!")
    _perform_attack()

func update(delta: float) -> String:
    # Return to idle after attack duration
    if time_in_state >= attack_duration:
        return "Idle"
    
    return ""

func exit(next_state: State = null) -> void:
    print("Attack complete!")
    super.exit(next_state)

func _perform_attack() -> void:
    # Attack logic here
    if _target:
        _target.take_damage(attack_damage)
```

### Conditional Transitions

```gdscript
class_name PatrolState extends State

func update(delta: float) -> String:
    # Check for player in range
    if _player_in_range():
        return "Chase"
    
    # Continue patrol
    return ""

func can_transition_to(to_state: State) -> bool:
    # Don't chase if health is low
    if to_state.name == "Chase":
        var health = get_sibling_component("HealthComponent")
        if health and health.current_health < 20:
            return false
    
    return true

func _player_in_range() -> bool:
    # Detection logic here
    return false
```

### Manual State Control

```gdscript
# Force a state change (bypasses can_transition_to)
state_machine.force_state("GameOver")

# Normal state change (respects conditions)
state_machine.change_state("Victory")

# Get current state
var current = state_machine.get_current_state()
print("Currently in: %s" % current.name)

# Check state history
var history = state_machine.get_history()
print("State history: %s" % " → ".join(history))
```

### Communication Between States

```gdscript
# State A
class_name StateA extends State

signal event_occurred(data)

func update(delta: float) -> String:
    # Emit event
    event_occurred.emit("important data")
    return ""

# State B
class_name StateB extends State

func enter(previous_state: State = null) -> void:
    super.enter(previous_state)
    
    # Connect to sibling state's signal
    var state_a = get_sibling_state("StateA")
    if state_a:
        state_a.event_occurred.connect(_on_event)

func _on_event(data) -> void:
    print("Received event: %s" % data)
```

---

## 🧪 Testing

Test scene: `sandbox/test_scenes/state_machine_test.tscn`

### Test Features

- **Auto Mode**: States automatically transition based on timers
- **Manual Mode**: Force specific states with keyboard
- **Visual Feedback**: Real-time state information
- **History Tracking**: See all state transitions
- **Debug Info**: Per-state custom information

### Test Controls

- **[1]** - Force Idle state (manual mode)
- **[2]** - Force Walk state (manual mode)
- **[3]** - Force Run state (manual mode)
- **[H]** - Show state history
- **[D]** - Debug print full info
- **[SPACE]** - Toggle auto/manual mode
- **[Q]** - Quit

### Running Tests

1. Open `state_machine_test.tscn`
2. Press F5 to run
3. Watch states automatically cycle: Idle → Walk → Run → Idle
4. Press SPACE to enter manual mode
5. Use 1/2/3 to manually control states

---

## ✅ SOLID Compliance

### Single Responsibility Principle (SRP)
- ✅ State: Handles one specific behavior
- ✅ StateMachine: Manages state lifecycle only

### Open/Closed Principle (OCP)
- ✅ New states extend State without modifying it
- ✅ StateMachine works with any State subclass

### Liskov Substitution Principle (LSP)
- ✅ Any State can be used in StateMachine
- ✅ All states follow the same lifecycle contract

### Interface Segregation Principle (ISP)
- ✅ States only implement methods they need
- ✅ Optional update methods (can leave empty)

### Dependency Inversion Principle (DIP)
- ✅ StateMachine depends on State abstraction
- ✅ No dependencies on concrete state types

---

## 🎨 Design Patterns

### State Pattern
Classic state pattern implementation where each state is an object with its own behavior.

### Observer Pattern
States emit signals that other states or systems can observe.

### Template Method
State base class provides lifecycle template, subclasses fill in details.

---

## 📊 Performance Considerations

### Memory
- Each state is a lightweight Node
- StateMachine maintains dictionary for O(1) lookup
- History tracking has configurable size limit

### Processing
- Only active state's update methods are called
- No polling or condition checking in StateMachine
- States request transitions (event-driven)

### Best Practices
- Keep states focused and simple
- Use signals for state-to-state communication
- Cache references in enter() if needed frequently
- Disable StateMachine when not needed

---

## 🔍 Common Patterns

### Timer-Based Transitions

```gdscript
class_name TimedState extends State

@export var duration: float = 2.0
@export var next_state: String = "NextState"

func update(delta: float) -> String:
    if time_in_state >= duration:
        return next_state
    return ""
```

### Condition-Based Transitions

```gdscript
class_name ConditionalState extends State

func update(delta: float) -> String:
    if _some_condition():
        return "StateA"
    elif _other_condition():
        return "StateB"
    return ""
```

### Input-Based Transitions

```gdscript
class_name InputState extends State

func update(delta: float) -> String:
    if Input.is_action_just_pressed("jump"):
        return "Jump"
    if Input.is_action_just_pressed("attack"):
        return "Attack"
    return ""
```

### State with Substates

```gdscript
class_name ParentState extends State

var _substate_machine: StateMachine

func enter(previous_state: State = null) -> void:
    super.enter(previous_state)
    # Initialize sub-state machine
    _substate_machine.change_state("InitialSubstate")
```

---

## 🚨 Common Pitfalls

### ❌ Don't: Forget to return state name

```gdscript
func update(delta: float) -> String:
    if some_condition:
        change_state("NextState")  # Wrong!
    # Missing return statement
```

### ✅ Do: Return the next state name

```gdscript
func update(delta: float) -> String:
    if some_condition:
        return "NextState"  # Correct!
    return ""
```

### ❌ Don't: Access states before enter()

```gdscript
func update(delta: float) -> String:
    var other = get_sibling_state("Other")
    # other might not be initialized yet!
```

### ✅ Do: Cache references in enter()

```gdscript
var _other_state: State

func enter(previous_state: State = null) -> void:
    super.enter(previous_state)
    _other_state = get_sibling_state("Other")
```

---

## 🎓 Advanced Techniques

### State Groups

```gdscript
# Group states by category
const MOVEMENT_STATES = ["Idle", "Walk", "Run", "Jump"]
const COMBAT_STATES = ["Attack", "Block", "Dodge"]

func is_in_movement() -> bool:
    return state_machine.get_current_state_name() in MOVEMENT_STATES
```

### Transition Validation

```gdscript
func can_transition_to(to_state: State) -> bool:
    # Check stamina before running
    if to_state.name == "Run":
        return _stamina > 20
    
    # Always allow idle
    if to_state.name == "Idle":
        return true
    
    return super.can_transition_to(to_state)
```

### State Data Passing

```gdscript
class_name StateWithData extends State

var transition_data: Dictionary = {}

func exit(next_state: State = null) -> void:
    # Pass data to next state
    if next_state and next_state.has_method("receive_data"):
        next_state.receive_data(transition_data)
    super.exit(next_state)

func receive_data(data: Dictionary) -> void:
    transition_data = data
```

---

## 📚 Related Documentation

- [Component Foundation](component_foundation.md)
- [SOLID Principles](../architecture/SOLID_PRINCIPLES.md)
- [Component Creation Guide](../guidelines/COMPONENT_CREATION.md)

---

## 🎯 Next Steps

Now that you have a powerful StateMachine:

1. Create states for your game entities
2. Combine with other components (Health, Movement, etc.)
3. Build complex AI behaviors
4. Implement player state management

The StateMachine is one of the most versatile components in the framework! 🎮⚔️
