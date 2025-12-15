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
│       ├── state_machine/
│       ├── health/
│       ├── movement/
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

**v0.1.0** - Foundation Phase
- Core component system
- ComponentHost implementation
- Basic testing sandbox

## 📝 License

[To be defined]

## 🤝 Contributing

This is a framework in active development. Documentation and guidelines will be updated as we establish patterns and best practices.
