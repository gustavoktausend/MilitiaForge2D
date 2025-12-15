# Component Foundation System

**Status**: ✅ Complete  
**Version**: 1.0.0  
**Last Updated**: 2024-12-13

## 📋 Overview

The Component Foundation System is the core of MilitiaForge2D. It provides the base classes and infrastructure for all components in the framework.

## 🏗️ Architecture

### Core Classes

#### `Component` (component.gd)

The abstract base class for all components. Defines the standard interface and lifecycle that all components must follow.

**Responsibilities**:
- Define component lifecycle contract
- Manage component state (enabled/disabled, initialized)
- Provide helper methods for component communication
- Emit lifecycle signals

**Key Methods**:
```gdscript
initialize(host: ComponentHost) -> void
component_ready() -> void
component_process(delta: float) -> void
component_physics_process(delta: float) -> void
cleanup() -> void
enable() -> void
disable() -> void
```

**Signals**:
- `component_initialized` - Emitted when component is initialized
- `component_error(message: String)` - Emitted on errors

---

#### `ComponentHost` (component_host.gd)

Manages the lifecycle and coordination of attached components. This is the central node that components are attached to.

**Responsibilities**:
- Discover and register components
- Initialize components in correct order
- Route lifecycle calls to components
- Provide component lookup and retrieval
- Coordinate component cleanup

**Key Methods**:
```gdscript
add_component(component: Component) -> void
remove_component(component: Component) -> void
get_component(component_type: String) -> Component
get_components(component_type: String) -> Array[Component]
has_component(component_type: String) -> bool
enable_all_components() -> void
disable_all_components() -> void
```

**Signals**:
- `component_added(component: Component)` - When component is added
- `component_removed(component: Component)` - When component is removed
- `all_components_ready` - When all components are initialized

---

## 🔄 Component Lifecycle

Components go through a standardized lifecycle managed by the ComponentHost:

```
1. Constructor (_init)
   ↓
2. Added to scene tree (_ready)
   ↓
3. initialize(host) - Component-specific setup
   ↓
4. component_ready() - Ready to operate
   ↓
5. component_process(delta) - Per-frame updates
   ↓
6. component_physics_process(delta) - Physics updates
   ↓
7. cleanup() - Cleanup when removed
```

### Lifecycle Details

**1. Constructor (`_init`)**
- Standard GDScript constructor
- Avoid heavy initialization here
- Use for setting up default values

**2. Node Ready (`_ready`)**
- Called when node enters scene tree
- Components should NOT use this directly
- ComponentHost uses this to discover components

**3. Initialize (`initialize(host)`)**
- First lifecycle method specific to components
- Receive reference to ComponentHost
- Perform component-specific initialization
- **Always call `super.initialize(host)` first**

**4. Component Ready (`component_ready()`)**
- Called after all components are initialized
- Safe to access sibling components here
- Perform setup requiring other components

**5. Process (`component_process(delta)`)**
- Called every frame if overridden
- Only override if needed
- Use for per-frame logic

**6. Physics Process (`component_physics_process(delta)`)**
- Called every physics frame if overridden
- Only override if needed
- Use for physics-related updates

**7. Cleanup (`cleanup()`)**
- Called when component is removed
- Disconnect signals, free resources
- **Always call `super.cleanup()` last**

---

## 💡 Usage Examples

### Basic Setup

```gdscript
# 1. Create a scene with ComponentHost
var host = ComponentHost.new()
host.name = "Player"
add_child(host)

# 2. Add components
var health = HealthComponent.new()
var movement = MovementComponent.new()

host.add_component(health)
host.add_component(movement)

# 3. Components are automatically initialized
```

### Accessing Components

```gdscript
# Get a specific component
var health = host.get_component("HealthComponent")

# Get all components of a type
var all_movements = host.get_components("MovementComponent")

# Check if component exists
if host.has_component("InventoryComponent"):
    print("Has inventory!")
```

### Component Communication

```gdscript
# From within a component - access sibling components
class_name MyComponent extends Component

func component_ready():
    # Get a sibling component
    var health = get_sibling_component("HealthComponent")
    if health:
        health.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int, old_health: int):
    print("Health changed!")
```

### Enabling/Disabling Components

```gdscript
# Disable a specific component
health_component.disable()

# Enable it again
health_component.enable()

# Disable all components on a host
host.disable_all_components()
```

---

## 🧪 Testing

A complete test scene is provided: `sandbox/test_scenes/component_foundation_test.tscn`

### Test Scene Features

- Interactive component addition/removal
- Enable/disable testing
- Debug information display
- Lifecycle verification

### Test Controls

- **[1]** - Add test component at runtime
- **[2]** - Remove last component
- **[3]** - Enable all components
- **[4]** - Disable all components
- **[D]** - Print debug information
- **[Q]** - Quit

### Running Tests

1. Open the project in Godot 4.x
2. Press F5 to run (test scene is set as main scene)
3. Check console output for lifecycle messages
4. Use keyboard controls to test functionality

---

## ✅ SOLID Compliance

### Single Responsibility Principle (SRP)
- ✅ Component: Defines component contract only
- ✅ ComponentHost: Manages components only

### Open/Closed Principle (OCP)
- ✅ New components extend Component without modifying it
- ✅ ComponentHost works with any Component subclass

### Liskov Substitution Principle (LSP)
- ✅ Any Component can be used wherever Component is expected
- ✅ All components follow the same lifecycle contract

### Interface Segregation Principle (ISP)
- ✅ Components only implement methods they need
- ✅ Lifecycle methods are optional (empty defaults)

### Dependency Inversion Principle (DIP)
- ✅ ComponentHost depends on Component abstraction
- ✅ No dependencies on concrete component types

---

## 📊 Performance Considerations

### Memory
- Components are lightweight Node-based objects
- ComponentHost maintains dictionaries for O(1) lookup by type
- Minimal overhead per component

### Processing
- Only components that override process methods are called
- Enable/disable mechanism allows skipping inactive components
- No reflection or dynamic lookups in hot paths

### Best Practices
- Only override process methods if needed
- Use signals for component communication (avoid polling)
- Disable components instead of removing when temporarily inactive
- Cache component references if accessed frequently

---

## 🔍 Common Patterns

### Component Dependencies

```gdscript
class_name DependentComponent extends Component

var _required_component: RequiredComponent

func component_ready():
    _required_component = get_sibling_component("RequiredComponent")
    
    if not _required_component:
        _emit_error("RequiredComponent not found!")
        disable()
        return
    
    # Safe to use _required_component now
```

### Optional Components

```gdscript
func component_ready():
    var optional = get_sibling_component("OptionalComponent")
    
    if optional:
        # Use enhanced functionality
    else:
        # Fallback behavior
```

### Component Communication via Signals

```gdscript
# Component A
signal data_changed(new_data)

# Component B
func component_ready():
    var component_a = get_sibling_component("ComponentA")
    if component_a:
        component_a.data_changed.connect(_on_data_changed)
```

---

## 🚨 Common Pitfalls

### ❌ Don't: Access components in `_ready()`
```gdscript
func _ready():
    # Components not initialized yet!
    var health = host.get_component("HealthComponent")  # May be null
```

### ✅ Do: Access components in `component_ready()`
```gdscript
func component_ready():
    # All components are initialized
    var health = get_sibling_component("HealthComponent")  # Safe
```

### ❌ Don't: Forget to call super methods
```gdscript
func initialize(host_node: ComponentHost):
    # Missing super.initialize(host_node) - breaks component!
```

### ✅ Do: Always call super
```gdscript
func initialize(host_node: ComponentHost):
    super.initialize(host_node)  # Always call first
    # Your code here
```

---

## 📚 Related Documentation

- [SOLID Principles](../architecture/SOLID_PRINCIPLES.md)
- [Component Creation Guide](../guidelines/COMPONENT_CREATION.md)

---

## 🎯 Next Steps

Now that the foundation is complete, you can:

1. Create your first real component (e.g., HealthComponent)
2. Build more complex components using this foundation
3. Create component combinations for common game patterns

The foundation is solid and ready for building upon! 🏗️
