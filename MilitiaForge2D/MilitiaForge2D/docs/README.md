# Documentation Index

Central hub for all MilitiaForge2D documentation.

## 🚀 Start Here

- **[Getting Started](../GETTING_STARTED.md)** - First steps with the framework
- **[Quick Reference](QUICK_REFERENCE.md)** - Cheat sheet for common tasks
- **[README](../README.md)** - Project overview

---

## 🏗️ Architecture

- **[SOLID Principles](architecture/SOLID_PRINCIPLES.md)** - How SOLID principles are applied in the framework

---

## 📖 Guidelines

- **[Component Creation Guide](guidelines/COMPONENT_CREATION.md)** - How to create new components
  - Component template
  - Best practices
  - Testing guidelines
  - Documentation standards

---

## 🧩 Components

### Core System
- **[Component Foundation](components/component_foundation.md)** - Complete documentation of the base system
  - Component class
  - ComponentHost class
  - Lifecycle details
  - Usage examples
  - Performance considerations

### Implemented Components

*As components are implemented, they will be documented here*

---

## 📚 Additional Resources

- **[Changelog](../CHANGELOG.md)** - Version history and changes
- **[Sandbox Tests](../sandbox/)** - Test scenes and examples

---

## 🗂️ Documentation Structure

```
docs/
├── README.md                          # This file
├── QUICK_REFERENCE.md                 # Quick reference guide
├── architecture/
│   └── SOLID_PRINCIPLES.md           # SOLID principles
├── guidelines/
│   └── COMPONENT_CREATION.md         # Component creation guide
└── components/
    └── component_foundation.md       # Component system docs
```

---

## 🔍 Finding What You Need

### I want to...

**...understand the framework architecture**
→ Read [SOLID Principles](architecture/SOLID_PRINCIPLES.md)

**...create my first component**
→ Read [Getting Started](../GETTING_STARTED.md) then [Component Creation Guide](guidelines/COMPONENT_CREATION.md)

**...look up a quick syntax**
→ Check [Quick Reference](QUICK_REFERENCE.md)

**...understand the component lifecycle**
→ See [Component Foundation](components/component_foundation.md#-component-lifecycle)

**...see examples**
→ Explore `sandbox/test_scenes/` and `sandbox/test_components/`

**...know what changed**
→ Read [Changelog](../CHANGELOG.md)

---

## 📝 Contributing to Documentation

When adding new components or features:

1. Create documentation in `docs/components/[component_name].md`
2. Follow the structure of existing documentation
3. Update this index with a link to the new documentation
4. Update CHANGELOG.md with changes
5. Add examples to the sandbox if applicable

---

*Last updated: 2024-12-13*
