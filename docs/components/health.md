# Health Component System

**Status**: ✅ Complete  
**Version**: 1.0.0  
**Last Updated**: 2024-12-13

## 📋 Overview

The Health Component System provides a complete damage/health management solution for 2D games. It includes health tracking, damage dealing, invincibility frames, regeneration, and area-based collision detection.

## 🎯 Use Cases

- Player health management
- Enemy health and death
- Breakable objects
- Damage zones (spikes, lava, etc.)
- Combat systems
- Boss fights with health bars

## 🏗️ Architecture

### Core Components

#### `HealthComponent` (health_component.gd)

Main health management component.

**Features**:
- Configurable max health
- Damage and healing systems
- Invincibility frames (i-frames)
- Optional health regeneration
- Critical health detection
- Death management
- Comprehensive signaling

**Key Methods**:
```gdscript
take_damage(amount: int, attacker: Node = null) -> int
heal(amount: int) -> int
set_health(new_health: int) -> void
kill() -> void
revive(revive_health: int = 0) -> void
get_current_health() -> int
get_health_percentage() -> float
is_dead() -> bool
is_invincible() -> bool
is_critical() -> bool
```

**Signals**:
```gdscript
health_changed(new_health, old_health)
damage_taken(amount, attacker)
healed(amount)
died()
invincibility_started()
invincibility_ended()
health_critical(current_health)
```

**Exports**:
- `max_health: int` - Maximum health
- `starting_health: int` - Starting health (0 = max)
- `critical_health_threshold: float` - Critical threshold (0.0-1.0)
- `invincibility_enabled: bool` - Enable i-frames
- `invincibility_duration: float` - I-frame duration
- `regeneration_enabled: bool` - Enable regen
- `regeneration_rate: float` - HP per second
- `can_die: bool` - Can health reach 0

---

#### `Hurtbox` (hurtbox.gd)

Area2D that receives damage from Hitboxes.

**Features**:
- Automatic HealthComponent integration
- Hit flash visual feedback
- Enable/disable functionality
- Collision detection

**Setup**:
```gdscript
# As Area2D child
var hurtbox = Hurtbox.new()
hurtbox.hit_flash_enabled = true
add_child(hurtbox)

# Add CollisionShape2D as child
```

**Collision Settings**:
- Layer: 2 (hurtbox layer)
- Mask: 4 (hitbox layer)

---

#### `Hitbox` (hitbox.gd)

Area2D that deals damage to Hurtboxes.

**Features**:
- Configurable damage amount
- One-shot or continuous damage
- Hit-once-per-target option
- Optional knockback
- Lifetime and activation delay
- Auto-deactivation

**Key Methods**:
```gdscript
activate() -> void
deactivate() -> void
reset() -> void
set_damage(new_damage: int) -> void
is_active() -> bool
```

**Exports**:
- `damage: int` - Damage amount
- `active: bool` - Currently active
- `hit_once_per_target: bool` - Only damage each target once
- `one_shot: bool` - Deactivate after first hit
- `apply_knockback: bool` - Apply knockback
- `knockback_force: float` - Knockback strength
- `lifetime: float` - Auto-expire time (0 = infinite)

**Collision Settings**:
- Layer: 4 (hitbox layer)
- Mask: 2 (hurtbox layer)

---

## 💡 Usage Examples

### Basic Health Setup

```gdscript
# On player
extends CharacterBody2D

@onready var health: HealthComponent = $ComponentHost.get_component("HealthComponent")

func _ready():
    health.health_changed.connect(_on_health_changed)
    health.died.connect(_on_died)

func _on_health_changed(new_health, old_health):
    print("Health: %d -> %d" % [old_health, new_health])

func _on_died():
    print("Player died!")
    queue_free()
```

### Damage Dealing

```gdscript
# Manual damage
health.take_damage(10)

# Damage with attacker reference
health.take_damage(15, attacker_node)

# Healing
health.heal(20)

# Set specific health
health.set_health(50)
```

### Hitbox/Hurtbox Setup

```gdscript
# Player with hurtbox (receives damage)
Player (CharacterBody2D)
├── ComponentHost
│   └── HealthComponent
├── Hurtbox (Area2D, layer=2, mask=4)
│   └── CollisionShape2D
└── Sprite

# Enemy with hitbox (deals damage)
Enemy (CharacterBody2D)
├── Hitbox (Area2D, layer=4, mask=2)
│   └── CollisionShape2D
└── Sprite
```

### Invincibility Frames

```gdscript
# Configure in HealthComponent
@export var invincibility_enabled: bool = true
@export var invincibility_duration: float = 0.5

# Visual feedback during invincibility
func _process(_delta):
    if health.is_invincible():
        modulate.a = 0.5  # Semi-transparent
    else:
        modulate.a = 1.0
```

### Health Regeneration

```gdscript
# Enable regeneration
health.regeneration_enabled = true
health.regeneration_rate = 5.0  # 5 HP per second
health.regeneration_delay = 3.0  # Delay after damage
```

### Critical Health Detection

```gdscript
# React to critical health
health.health_critical.connect(_on_critical)

func _on_critical(current: int):
    print("Critical health: %d" % current)
    # Play warning sound
    # Show red screen effect
    # Slow motion effect
```

### Knockback Integration

```gdscript
# Hitbox with knockback
var hitbox = Hitbox.new()
hitbox.damage = 10
hitbox.apply_knockback = true
hitbox.knockback_force = 300.0
```

### Death Handling

```gdscript
health.died.connect(_on_died)

func _on_died():
    # Play death animation
    $AnimationPlayer.play("death")
    
    # Disable controls
    if movement:
        movement.disable_movement()
    
    # Wait for animation
    await $AnimationPlayer.animation_finished
    
    # Respawn or game over
    _respawn()
```

---

## 🧪 Testing

Test scene: `sandbox/test_scenes/health_test.tscn`

### Test Features

- **Player**: Blue square with health and movement
- **Enemies**: Red squares that wander and deal damage
- **Health Bar**: Visual health representation
- **Real-time Stats**: Health, state, invincibility
- **Manual Controls**: Damage, heal, kill, revive
- **Regeneration**: Toggle on/off

### Test Controls

- **[WASD]** - Move player
- **[Shift]** - Sprint
- **[H]** - Heal 20 HP
- **[J]** - Take 10 damage
- **[K]** - Kill player
- **[R]** - Revive player
- **[T]** - Toggle regeneration
- **[D]** - Debug print
- **[Q]** - Quit

### What to Test

1. **Basic Damage**: Touch enemies, see health decrease
2. **Invincibility**: After damage, brief invincibility (flashing)
3. **Healing**: Press H to heal
4. **Critical Health**: Get below 25% health
5. **Death**: Let health reach 0
6. **Revive**: Press R to revive
7. **Regeneration**: Toggle with T, wait to see health regenerate
8. **Manual Damage**: Press J to test without enemies

---

## ✅ SOLID Compliance

- ✅ **SRP**: Each component has one responsibility
- ✅ **OCP**: Extend HealthComponent for custom behaviors
- ✅ **LSP**: Hitbox/Hurtbox are standard Area2D nodes
- ✅ **ISP**: Optional features (regen, knockback)
- ✅ **DIP**: Depends on Component abstraction

---

## 🔄 Integration Examples

### With State Machine

```gdscript
class_name DeadState extends State

func enter(previous_state: State = null):
    var health = get_sibling_component("HealthComponent")
    var movement = get_sibling_component("MovementComponent")
    
    movement.disable_movement()
    # Play death animation
    
func update(delta: float) -> String:
    # Wait for respawn
    if Input.is_action_just_pressed("respawn"):
        return "Respawn"
    return ""
```

### With Animations

```gdscript
health.damage_taken.connect(_on_damage)
health.health_critical.connect(_on_critical)

func _on_damage(amount, attacker):
    $AnimationPlayer.play("hit")
    $AudioPlayer.play()

func _on_critical(current):
    $AnimationPlayer.play("low_health_warning")
```

### With UI

```gdscript
health.health_changed.connect(_update_health_bar)

func _update_health_bar(new_health, old_health):
    var percentage = float(new_health) / health.max_health
    $HealthBar.value = percentage * 100
```

---

## 📊 Performance

- Lightweight components
- Efficient signal system
- No frame-by-frame calculations (except optional regen)
- Collision-based damage is performant

---

## 🚨 Common Pitfalls

### ❌ Don't: Forget collision layers

```gdscript
# Wrong - won't detect hits
Hurtbox: layer=1, mask=1
Hitbox: layer=1, mask=1
```

### ✅ Do: Use separate layers

```gdscript
# Correct
Hurtbox: layer=2, mask=4
Hitbox: layer=4, mask=2
```

### ❌ Don't: Apply damage every frame

```gdscript
# Wrong - damages continuously
func _on_hitbox_entered(area):
    health.take_damage(10)  # Called every frame!
```

### ✅ Do: Use hit_once_per_target

```gdscript
# Correct
hitbox.hit_once_per_target = true
```

---

## 📚 Related Documentation

- [Component Foundation](component_foundation.md)
- [Movement System](movement.md)
- [State Machine](state_machine.md)

---

## 🎯 Next Steps

With the Health System complete:

1. Combine with State Machine (death state, hurt state)
2. Add animations for damage/death
3. Create health bar UI
4. Implement enemy AI with health
5. Add power-ups and health pickups

The Health System is production-ready! 💚⚔️
