# Quick Reference - State Machine

## Creating a State

```gdscript
class_name MyState extends State

@export var my_duration: float = 2.0

func enter(previous_state: State = null) -> void:
    super.enter(previous_state)
    # Setup when entering this state

func update(delta: float) -> String:
    # Per-frame logic
    if time_in_state >= my_duration:
        return "NextState"  # Transition to NextState
    return ""  # Stay in current state

func exit(next_state: State = null) -> void:
    # Cleanup when exiting
    super.exit(next_state)
```

## Using State Machine

```gdscript
# Setup
var state_machine = StateMachine.new()
state_machine.initial_state_name = "Idle"
state_machine.debug_transitions = true
host.add_component(state_machine)

# Add states as children
var idle = IdleState.new()
idle.name = "Idle"
state_machine.add_child(idle)

# Change state
state_machine.change_state("Walk")

# Force state (bypass conditions)
state_machine.force_state("GameOver")

# Get current state
var current = state_machine.get_current_state()
print(current.name)
```

## State Lifecycle

```
enter(previous_state)
    ↓
update(delta) → return "NextState" or ""
physics_update(delta) → return "NextState" or ""
    ↓
exit(next_state)
```

## Common Patterns

### Timer-Based
```gdscript
func update(delta: float) -> String:
    if time_in_state >= duration:
        return "NextState"
    return ""
```

### Condition-Based
```gdscript
func update(delta: float) -> String:
    if health <= 0:
        return "Dead"
    if enemy_nearby:
        return "Combat"
    return ""
```

### Input-Based
```gdscript
func update(delta: float) -> String:
    if Input.is_action_just_pressed("jump"):
        return "Jump"
    return ""
```

## Key Methods

```gdscript
# State methods
enter(previous_state)
update(delta) -> String
physics_update(delta) -> String
exit(next_state)
request_transition(state_name)
can_transition_to(to_state) -> bool
get_sibling_state(name) -> State

# StateMachine methods
change_state(state_name) -> bool
force_state(state_name) -> bool
get_current_state() -> State
get_current_state_name() -> String
get_state(state_name) -> State
get_history() -> Array[String]
```

## Signals

```gdscript
# StateMachine signals
state_changed(from_state, to_state)
transition_blocked(from_state, to_state, reason)

# State signals
state_entered(previous_state)
state_exited(next_state)
transition_requested(to_state_name)
```
