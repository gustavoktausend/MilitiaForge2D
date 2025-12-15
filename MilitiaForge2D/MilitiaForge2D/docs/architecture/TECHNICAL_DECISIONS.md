# Technical Decisions & Architecture

This document records all technical and architectural decisions made during the development of MilitiaForge2D's foundation system.

---

## 🎯 Core Design Philosophy

### Component-Based Architecture
**Decision**: Use a component-based system where functionality is added through modular components attached to a host.

**Rationale**:
- Maximum reusability across different game types
- Easy to test components in isolation
- Clear separation of concerns
- Follows composition over inheritance principle
- Highly extensible without modifying core code

**Alternatives Considered**:
- Traditional inheritance hierarchy: Rejected due to rigidity and deep coupling
- Pure ECS (Entity Component System): Rejected as overly complex for 2D games in Godot

---

## 🏗️ Implementation Decisions

### 1. Component as Node vs Resource

**Decision**: Components extend `Node` rather than `Resource`

**Rationale**:
- Visible in editor scene tree (better debugging)
- Can use node lifecycle (_ready, _process)
- Easier to attach/detach in editor
- Can have child nodes if needed
- Better integration with Godot's existing systems

**Trade-offs**:
- Slightly higher memory overhead
- Cannot be stored directly in resources
- More complex serialization

**Alternatives Considered**:
- Resource-based: Lighter but harder to debug and less editor-friendly
- Hybrid approach: Overly complex for initial implementation

---

### 2. Lifecycle Management

**Decision**: ComponentHost manages all component lifecycle calls

**Rationale**:
- Centralized control ensures correct initialization order
- Prevents components from bypassing lifecycle
- Makes it impossible to forget initialization steps
- Enables future optimization (batch processing, etc.)

**Implementation Details**:
```
initialize() → component_ready() → component_process() → cleanup()
```

**Why Not Use Godot's Built-in Lifecycle?**:
- `_ready()` is called before other components exist
- Need custom initialization after all components are added
- Want consistent behavior across runtime and editor-added components

---

### 3. Type-Based Component Lookup

**Decision**: Store components in dictionaries by class name for O(1) lookup

**Rationale**:
- Fast component retrieval (constant time)
- Type-safe (using class names)
- Supports multiple components of same type
- No reflection needed in hot paths

**Implementation**:
```gdscript
_components_by_type: Dictionary = {
    "HealthComponent": [health1, health2],
    "MovementComponent": [movement1]
}
```

**Alternatives Considered**:
- Linear search: Too slow for many components
- String tags: Less type-safe, more error-prone
- Generic get with type parameter: Not well supported in GDScript

---

### 4. Optional Process Methods

**Decision**: Components only override process methods if they need them

**Rationale**:
- Performance: No unnecessary calls to empty methods
- Clarity: Clear which components need updates
- Flexibility: Components can be pure data containers

**Implementation**:
- Base `Component` provides empty default implementations
- ComponentHost calls methods on all components
- Components that don't override simply do nothing (fast)

---

### 5. Signal-Based Communication

**Decision**: Components communicate via signals, not direct method calls

**Rationale**:
- Loose coupling between components
- Easy to add/remove listeners
- Follows Godot's event-driven patterns
- Supports one-to-many communication naturally

**Example**:
```gdscript
# Component A
signal health_changed(new_value)

# Component B
comp_a.health_changed.connect(_on_health_changed)
```

**Why Not Direct Calls?**:
- Creates tight coupling
- Harder to test in isolation
- Violates dependency inversion principle

---

### 6. Enable/Disable vs Add/Remove

**Decision**: Components can be disabled without removing them

**Rationale**:
- Temporary deactivation is common (cutscenes, pausing, etc.)
- Removing and re-adding is expensive
- State is preserved when disabled
- Can be toggled quickly

**Use Cases**:
- Disable movement during dialogue
- Disable AI during cutscenes
- Disable input during animations

---

## 📐 SOLID Application Details

### Single Responsibility Principle

**Component Class**:
- Only responsibility: Define component contract
- Does NOT: Manage multiple components, handle scene logic

**ComponentHost Class**:
- Only responsibility: Manage component lifecycle
- Does NOT: Implement game logic, render graphics

### Open/Closed Principle

**How We Achieve It**:
- Base `Component` class is closed for modification
- New functionality added by creating new component classes
- No need to touch core code for new features

**Example**:
```gdscript
# Core stays the same
class_name Component extends Node

# New feature = new class
class_name CustomComponent extends Component
```

### Liskov Substitution Principle

**Guarantee**:
- Any `Component` subclass works wherever `Component` is expected
- All components follow same lifecycle contract
- ComponentHost works with any component type

### Interface Segregation Principle

**Implementation**:
- Components only implement methods they use
- No forced implementation of unused methods
- Optional lifecycle methods (can leave empty)

### Dependency Inversion Principle

**How We Achieve It**:
- ComponentHost depends on `Component` abstraction
- Not on concrete component implementations
- Components can be swapped without changing host

---

## 🔧 Performance Considerations

### Memory

**Decisions**:
- Components are lightweight nodes
- Dictionary storage for fast lookup
- Arrays for iteration order

**Memory Profile** (per component):
- Base overhead: ~200 bytes (Node)
- Component data: Variable (exported vars)
- Dictionary entry: ~100 bytes

### Processing

**Optimizations**:
- Only components that override process are called
- Enable/disable allows skipping inactive components
- No reflection in hot paths
- Type dictionaries for O(1) lookup

**Benchmark Targets**:
- 100+ components: <1ms per frame
- 1000+ components: <5ms per frame

---

## 🧪 Testing Strategy

### Test Scene Architecture

**Decision**: Interactive test scene with visual feedback

**Rationale**:
- Visual confirmation of behavior
- Manual testing of edge cases
- Useful for debugging
- Serves as example for users

**Components**:
- UI panel with information
- Keyboard controls for actions
- Console output for verification
- Test components with configurable behavior

---

## 📝 Documentation Strategy

### Multi-Level Documentation

**Decision**: Three levels of documentation

1. **Quick Reference**: Immediate answers
2. **Getting Started**: Learning path
3. **Complete Docs**: Deep dive reference

**Rationale**:
- Different users need different depths
- Quick answers prevent frustration
- Comprehensive docs for advanced use

### Code Documentation

**Standards**:
- Every public method documented
- GDScript doc comments (##)
- Type hints everywhere
- Region organization

**Example**:
```gdscript
## Takes damage and reduces health.
## @param amount: Damage amount (positive integer)
## Returns: true if still alive, false if died
func take_damage(amount: int) -> bool:
```

---

## 🔮 Future Considerations

### Planned Features

1. **Component Dependencies**:
   - Declare required components
   - Auto-validation
   - Clear error messages

2. **Event Bus**:
   - Global event system
   - Component-to-component communication
   - Decoupled architecture

3. **Component Pooling**:
   - Reuse components instead of creating new
   - Performance optimization
   - Memory efficiency

4. **Serialization**:
   - Save/load component state
   - Network synchronization
   - Undo/redo support

### Extensibility Points

The architecture is designed to support:
- Custom lifecycle hooks
- Component validators
- Middleware/interceptors
- Hot reloading
- Runtime composition

---

## 🎓 Lessons Learned

### What Worked Well

✅ Component as Node for editor integration
✅ Centralized lifecycle management
✅ Signal-based communication
✅ Comprehensive documentation
✅ Interactive test scene

### What Could Be Improved

⚠️ Component discovery could be more flexible
⚠️ Need better error messages for common mistakes
⚠️ Could benefit from component templates in editor

### Changes from Initial Design

**Changed**: Originally planned Resource-based components
**To**: Node-based components
**Why**: Better editor integration and debugging

---

## 📚 References

- [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Component Pattern](https://gameprogrammingpatterns.com/component.html)
- [ECS Architecture](https://en.wikipedia.org/wiki/Entity_component_system)

---

*This document will be updated as we make new architectural decisions.*

**Last Updated**: 2024-12-13
**Status**: Foundation Complete ✅
