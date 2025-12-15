# Getting Started with MilitiaForge2D

Quick guide to start using the MilitiaForge2D component framework.

## 🚀 First Steps

### 1. Open the Project

Open `MilitiaForge2D` in Godot 4.x (version 4.3+ recommended).

### 2. Run the Test Scene

Press **F5** to run the test scene (`component_foundation_test.tscn`).

You should see:
- A UI panel with component information
- Console output showing component lifecycle
- Interactive controls to test the system

### 3. Explore the Code

Key files to understand:
```
militia_forge/core/
├── component.gd          # Base component class
└── component_host.gd     # Component manager

sandbox/test_components/
└── test_component.gd     # Example component

docs/
├── QUICK_REFERENCE.md    # Quick reference
└── components/
	└── component_foundation.md  # Full documentation
```

---

## 📝 Creating Your First Component

### Step 1: Create the Script

Create a new script in `militia_forge/components/`:

```gdscript
## My First Component
## A simple component that does something cool!

class_name MyFirstComponent extends Component

#region Exports
@export var coolness_level: int = 100
#endregion

#region Lifecycle
func component_ready() -> void:
	print("My component is ready with coolness: %d" % coolness_level)

func component_process(delta: float) -> void:
	# Do something every frame
	pass
#endregion
```

### Step 2: Use the Component

Create a scene or use code:

```gdscript
# In a scene script or test
var host = ComponentHost.new()
add_child(host)

var my_component = MyFirstComponent.new()
my_component.coolness_level = 200
host.add_component(my_component)
```

### Step 3: Test It

Add your component to the test scene or create a new test scene in `sandbox/test_scenes/`.

---

## 🎯 Common Use Cases

### Adding Multiple Components

```gdscript
var host = ComponentHost.new()
host.name = "Player"

# Add various components
host.add_component(HealthComponent.new())
host.add_component(MovementComponent.new())
host.add_component(InventoryComponent.new())

add_child(host)
```

### Components Talking to Each Other

```gdscript
# In one component
class_name ComponentA extends Component

signal something_happened(data)

func do_something():
	something_happened.emit("Important data")

# In another component
class_name ComponentB extends Component

func component_ready():
	var comp_a = get_sibling_component("ComponentA")
	if comp_a:
		comp_a.something_happened.connect(_on_something_happened)

func _on_something_happened(data):
	print("Received: %s" % data)
```

### Disabling Components Temporarily

```gdscript
# Disable during cutscene
player_movement.disable()
show_cutscene()
player_movement.enable()
```

---

## 📚 Learning Path

1. **Read**: [`docs/QUICK_REFERENCE.md`](docs/QUICK_REFERENCE.md)
2. **Understand**: [`docs/architecture/SOLID_PRINCIPLES.md`](docs/architecture/SOLID_PRINCIPLES.md)
3. **Practice**: Run and modify `sandbox/test_scenes/component_foundation_test.tscn`
4. **Create**: Make your own component following [`docs/guidelines/COMPONENT_CREATION.md`](docs/guidelines/COMPONENT_CREATION.md)
5. **Deep Dive**: Read [`docs/components/component_foundation.md`](docs/components/component_foundation.md)

---

## 🐛 Troubleshooting

### Component not initializing?

- Check that it's a child of a `ComponentHost`
- Ensure you called `super.initialize(host)` in your override
- Verify the component extends `Component`

### Can't find sibling component?

- Access components only in `component_ready()`, not `_ready()`
- Check the component class name is correct
- Use `host.debug_print_components()` to see all components

### Component not processing?

- Make sure you've overridden `component_process()` or `component_physics_process()`
- Check if the component is enabled: `component.is_enabled()`
- Verify the ComponentHost is in the scene tree

---

## 💡 Tips

- **Use the sandbox**: Test components in isolation before using them in your game
- **Keep components focused**: Each component should have one clear responsibility
- **Export variables**: Make components configurable through the editor
- **Use signals**: Let components communicate without tight coupling
- **Read the docs**: The documentation is comprehensive and helpful

---

## 🤝 Next Steps

Now that you understand the basics:

1. Create a real component for your game
2. Test it in the sandbox
3. Document it following the existing patterns
4. Share your patterns and improvements!

Happy developing with MilitiaForge2D! 🎮⚔️
