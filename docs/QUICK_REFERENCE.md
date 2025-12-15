# Quick Reference - Component System

## Creating a Component

```gdscript
class_name MyComponent extends Component

@export var my_parameter: int = 100

func initialize(host_node: ComponentHost) -> void:
    super.initialize(host_node)
    # Component initialization

func component_ready() -> void:
    # Access sibling components here
    pass

func component_process(delta: float) -> void:
    # Per-frame updates (optional)
    pass

func cleanup() -> void:
    # Cleanup code
    super.cleanup()
```

## Using Components

```gdscript
# Create host
var host = ComponentHost.new()
add_child(host)

# Add component
var component = MyComponent.new()
host.add_component(component)

# Get component
var my_comp = host.get_component("MyComponent")

# Remove component
host.remove_component(component)
```

## Component Lifecycle Order

1. `_init()` - Constructor
2. `_ready()` - Added to tree
3. `initialize(host)` - Component setup
4. `component_ready()` - All components ready
5. `component_process(delta)` - Every frame
6. `component_physics_process(delta)` - Physics frame
7. `cleanup()` - Being removed

## Key Rules

✅ **Always** call `super` in lifecycle methods
✅ Access sibling components in `component_ready()`
✅ Only override process methods if needed
✅ Use signals for component communication

❌ **Never** access components in `_ready()`
❌ **Never** forget to call super methods
❌ **Never** do heavy work in constructor

## Useful Methods

```gdscript
# From within a component
get_sibling_component("ComponentName")
get_sibling_components("ComponentName")
get_host()
enable() / disable()
is_enabled()

# From ComponentHost
add_component(component)
remove_component(component)
get_component("ComponentName")
get_components("ComponentName")
has_component("ComponentName")
enable_all_components()
disable_all_components()
```
