# MilitiaForge2D

A modular, component-based framework for rapid 2D game development in Godot 4.x

## 🎯 Vision

MilitiaForge2D is designed to accelerate 2D game development by providing a robust, SOLID-principled component system that allows developers to build games faster through reusable, parametrizable, and modular components.

## 🏗️ Architecture

The framework follows **SOLID principles** and implements a component-based architecture where:
- **Components** are self-contained, reusable pieces of functionality
- **ComponentHost** manages the lifecycle and coordination of attached components
- **Sandbox** provides isolated testing environments for components

## 📁 Project Structure

```
MilitiaForge2D/
├── docs/                          # Documentation
│   ├── architecture/              # Architectural decisions and patterns
│   ├── components/                # Component-specific documentation
│   └── guidelines/                # Development guidelines and best practices
├── militia_forge/                 # Core framework code
│   ├── core/                      # Foundation classes
│   │   ├── component.gd          # Base Component class
│   │   └── component_host.gd     # Component manager
│   └── components/                # Reusable components
│       ├── state_machine/        # State machine component
│       │   ├── state.gd         # Base State class
│       │   └── state_machine.gd # StateMachine component
│       ├── movement/             # Movement components
│       │   ├── movement_component.gd  # Base movement class
│       │   └── topdown_movement.gd    # Top-down movement
│       ├── health/               # Health system
│       │   ├── health_component.gd    # Health management
│       │   ├── hurtbox.gd            # Damage receiver
│       │   └── hitbox.gd             # Damage dealer
│       ├── input/                # Input system
│       │   ├── input_component.gd    # Input management
│       │   └── input_action.gd       # Action definition
│       └── inventory/
├── sandbox/                       # Testing environment
│   ├── test_scenes/              # Test scenes for components
│   └── test_components/          # Test-specific components
├── examples/                      # Example games and use cases
└── project.godot                 # Godot project configuration
```

## 🚀 Getting Started

1. Open the project in Godot 4.x
2. Navigate to `sandbox/test_scenes/` to see component demonstrations
3. Check `docs/guidelines/` for component creation best practices

## 📖 Documentation

- [SOLID Principles](docs/architecture/SOLID_PRINCIPLES.md)
- [Component Creation Guide](docs/guidelines/COMPONENT_CREATION.md)

## 🔧 Current Version

**v0.7.0** - Optional Components (Complete Framework)
- Core component system with SOLID principles
- ComponentHost for lifecycle management
- StateMachine for behavior management  
- Movement system (TopDownMovement, BoundedMovement)
- Health system (damage, healing, death)
- Input system (centralized input management)
- Combat system (Projectile, Weapon, Spawner)
- Environment system (Scroll)
- Progression system (PowerUp, Score)
- Effects system (ParticleEffect)
- Audio system (Sound, Music)
- **14 complete components!**
- Comprehensive testing sandbox
- Complete documentation

## 📝 License

[To be defined]

## 🤝 Contributing

This is a framework in active development. Documentation and guidelines will be updated as we establish patterns and best practices.
