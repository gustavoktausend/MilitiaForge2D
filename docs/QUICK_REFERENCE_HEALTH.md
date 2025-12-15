# Quick Reference - Health System

## HealthComponent

### Basic Usage

```gdscript
# Get component
var health: HealthComponent = $ComponentHost.get_component("HealthComponent")

# Take damage
health.take_damage(10)
health.take_damage(15, attacker_node)

# Heal
health.heal(20)

# Kill/Revive
health.kill()
health.revive()
health.revive(50)  # Revive with 50 HP

# Set health directly
health.set_health(75)
```

### Status Queries

```gdscript
# Get health info
var current = health.get_current_health()
var max = health.get_max_health()
var percentage = health.get_health_percentage()  # 0.0 to 1.0

# Check states
if health.is_dead():
    pass
if health.is_alive():
    pass
if health.is_invincible():
    pass
if health.is_critical():
    pass
if health.is_full_health():
    pass
```

### Signals

```gdscript
health.health_changed.connect(func(new_hp, old_hp): pass)
health.damage_taken.connect(func(amount, attacker): pass)
health.healed.connect(func(amount): pass)
health.died.connect(func(): pass)
health.invincibility_started.connect(func(): pass)
health.invincibility_ended.connect(func(): pass)
health.health_critical.connect(func(current): pass)
```

## Hitbox & Hurtbox

### Setup Collision

```gdscript
# Hurtbox (receives damage)
# Layer: 2, Mask: 4

# Hitbox (deals damage)
# Layer: 4, Mask: 2
```

### Hurtbox

```gdscript
# As Area2D node
var hurtbox = Hurtbox.new()
hurtbox.hit_flash_enabled = true
hurtbox.active = true
add_child(hurtbox)
```

### Hitbox

```gdscript
# As Area2D node
var hitbox = Hitbox.new()
hitbox.damage = 15
hitbox.hit_once_per_target = true
hitbox.apply_knockback = true
hitbox.knockback_force = 300.0
add_child(hitbox)

# Control
hitbox.activate()
hitbox.deactivate()
hitbox.reset()
hitbox.set_damage(20)
```

## Common Patterns

### Player Health

```gdscript
extends CharacterBody2D

var health: HealthComponent

func _ready():
    health = $ComponentHost.get_component("HealthComponent")
    health.died.connect(_on_died)

func _on_died():
    # Disable movement
    $Movement.disable_movement()
    # Play death animation
    $AnimationPlayer.play("death")
```

### Health Bar UI

```gdscript
func _ready():
    health.health_changed.connect(_update_ui)

func _update_ui(new_health, _old_health):
    var percent = health.get_health_percentage()
    $HealthBar.value = percent * 100
```

### Invincibility Visual

```gdscript
func _process(_delta):
    if health.is_invincible():
        modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
    else:
        modulate.a = 1.0
```

### Regeneration

```gdscript
# Enable regen
health.regeneration_enabled = true
health.regeneration_rate = 5.0  # HP/sec
health.regeneration_delay = 3.0  # Delay after damage
```

### Knockback

```gdscript
# In hitbox
hitbox.apply_knockback = true
hitbox.knockback_force = 400.0
hitbox.knockback_direction = Vector2.LEFT
# If direction is zero, uses attacker->target direction
```

## Configuration

```gdscript
# Health settings
@export var max_health: int = 100
@export var starting_health: int = 0  # 0 = use max_health
@export var critical_health_threshold: float = 0.25  # 25%

# Invincibility
@export var invincibility_enabled: bool = true
@export var invincibility_duration: float = 0.5

# Regeneration
@export var regeneration_enabled: bool = false
@export var regeneration_rate: float = 5.0
@export var regeneration_delay: float = 3.0

# Advanced
@export var can_die: bool = true
```

## Tips

- ✅ Use separate collision layers (2 for hurtbox, 4 for hitbox)
- ✅ Enable hit_once_per_target for continuous hitboxes
- ✅ Connect to signals for animations and effects
- ✅ Use invincibility frames after damage
- ✅ Visual feedback during invincibility (flashing)
- ❌ Don't manually damage every frame
- ❌ Don't forget to set up collision layers
