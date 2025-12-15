# Component Creation Guide

This guide provides best practices and guidelines for creating components in the MilitiaForge2D framework.

## 🎯 Component Philosophy

A component is a **self-contained, reusable piece of functionality** that can be attached to a `ComponentHost` to add specific behaviors or capabilities.

### Key Principles

1. **Single Responsibility**: Each component does ONE thing well
2. **Parametrizable**: Expose configuration through exported variables
3. **Modular**: Components should work independently or together
4. **Testable**: Can be tested in isolation in the sandbox
5. **Documented**: Clear documentation of purpose and usage

---

## 📋 Component Lifecycle

Every component follows a standardized lifecycle managed by the `ComponentHost`:

```gdscript
1. Constructor: _init()
2. Node ready: _ready()
3. Component initialization: initialize(host)
4. Component ready: component_ready()
5. Per-frame update: component_process(delta)
6. Physics update: component_physics_process(delta)
7. Cleanup: cleanup()
```

---

## 🏗️ Component Template

Use this template as a starting point for all new components:

```gdscript
## [Component Name]
##
## Brief description of what this component does.
## 
## @tutorial: Link to tutorial or documentation
## @experimental

class_name [ComponentName] extends Component

#region Signals
## Emitted when [event happens]
signal [event_name]([parameters])
#endregion

#region Exports
## [Description of this parameter]
@export var [parameter_name]: [Type] = [default_value]

@export_group("Advanced")
## [Description of advanced parameter]
@export var [advanced_parameter]: [Type] = [default_value]
#endregion

#region Private Variables
var _[private_variable]: [Type]
#endregion

#region Lifecycle Methods
## Called when component is first initialized by the host
func initialize(host: ComponentHost) -> void:
    super.initialize(host)
    # Component-specific initialization

## Called when component is ready after being added to the scene tree
func component_ready() -> void:
    # Setup code here
    pass

## Called every frame (if needed)
func component_process(delta: float) -> void:
    # Per-frame logic here
    pass

## Called every physics frame (if needed)
func component_physics_process(delta: float) -> void:
    # Physics logic here
    pass

## Called when component is being removed
func cleanup() -> void:
    # Cleanup code here
    pass
#endregion

#region Public Methods
## [Description of what this method does]
## [param_name]: [Description of parameter]
## Returns: [Description of return value]
func [method_name]([parameters]) -> [ReturnType]:
    pass
#endregion

#region Private Methods
func _[private_method]([parameters]) -> [ReturnType]:
    pass
#endregion
```

---

## ✅ Best Practices

### 1. Use Regions for Organization

Organize your code into logical regions:
- Signals
- Exports (parameters)
- Private Variables
- Lifecycle Methods
- Public Methods
- Private Methods

### 2. Export Variables for Parameterization

Make components configurable through the editor:

```gdscript
# ✅ GOOD - Configurable
@export var max_health: int = 100
@export var regeneration_rate: float = 5.0

# ❌ BAD - Hardcoded
const MAX_HEALTH = 100
```

### 3. Use Type Hints

Always specify types for better error checking:

```gdscript
# ✅ GOOD
func take_damage(amount: int) -> void:
    pass

# ❌ BAD
func take_damage(amount):
    pass
```

### 4. Document Everything

Use GDScript documentation comments:

```gdscript
## Takes damage and reduces current health.
##
## If health reaches zero or below, emits the [signal died] signal.
##
## @param amount: The amount of damage to take (must be positive)
func take_damage(amount: int) -> void:
    pass
```

### 5. Emit Signals for Important Events

Allow other components and systems to react to events:

```gdscript
signal health_changed(new_health: int, old_health: int)
signal died()

func take_damage(amount: int) -> void:
    var old_health = current_health
    current_health -= amount
    health_changed.emit(current_health, old_health)
    
    if current_health <= 0:
        died.emit()
```

### 6. Call Super Methods

When overriding lifecycle methods, call the parent implementation:

```gdscript
func initialize(host: ComponentHost) -> void:
    super.initialize(host)  # Always call super first
    # Your initialization code
```

### 7. Validate Input

Check for invalid parameters and handle edge cases:

```gdscript
func take_damage(amount: int) -> void:
    if amount < 0:
        push_warning("Damage amount cannot be negative")
        return
    
    # Process damage
```

---

## 🧪 Testing Components

Every component should have a corresponding test scene in `sandbox/test_scenes/`:

1. Create a test scene: `test_[component_name].tscn`
2. Add a `ComponentHost` node
3. Attach your component
4. Add visual feedback or debug output
5. Test various parameter configurations

### Example Test Scene Structure

```
test_health_component.tscn
├── ComponentHost (with HealthComponent attached)
├── UI (CanvasLayer)
│   ├── HealthBar
│   └── DebugLabel
└── TestController (script to trigger damage/healing)
```

---

## 📝 Component Checklist

Before marking a component as complete:

- [ ] Follows the component template structure
- [ ] Uses proper regions for organization
- [ ] All public methods are documented
- [ ] Exports key parameters for customization
- [ ] Emits signals for important events
- [ ] Includes type hints everywhere
- [ ] Has a test scene in sandbox
- [ ] Has documentation in `docs/components/`
- [ ] Follows SOLID principles
- [ ] Validated and tested in isolation

---

## 🎓 Example: Creating a Simple Component

See `docs/components/health_component.md` for a complete walkthrough of creating a component from scratch.

---

*This guide will evolve as we discover new patterns and best practices.*
