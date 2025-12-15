## PowerUp Component
##
## Manages collectible power-ups with various effects and behaviors.
## Generic component useful for any game with collectibles.
##
## Features:
## - Multiple power-up types (health, ammo, weapon, speed, shield, score)
## - Automatic collection on overlap
## - Temporary vs permanent effects
## - Stacking effects
## - Expiration/lifetime
## - Visual feedback
## - Magnetic attraction (optional)
##
## @tutorial(Progression): res://docs/components/progression.md

class_name PowerUpComponent extends Component

#region Signals
## Emitted when power-up is collected
signal collected(collector: Node, powerup_type: PowerUpType)

## Emitted when power-up effect expires
signal effect_expired(powerup_type: PowerUpType)

## Emitted when power-up is about to expire (warning)
signal expiring_soon(time_remaining: float)
#endregion

#region Enums
## Power-up types
enum PowerUpType {
	HEALTH,       ## Restore health
	AMMO,         ## Add ammo
	WEAPON,       ## Weapon upgrade
	SPEED,        ## Speed boost
	SHIELD,       ## Temporary shield
	SCORE,        ## Bonus points
	CUSTOM        ## Custom effect (use signals)
}
#endregion

#region Exports
@export_group("PowerUp")
## Type of power-up
@export var powerup_type: PowerUpType = PowerUpType.HEALTH

## Value/amount of the power-up
@export var value: int = 20

## Whether effect is temporary
@export var temporary: bool = false

## Duration of temporary effect (seconds)
@export var duration: float = 5.0

## Whether power-up can be stacked
@export var stackable: bool = false

## Maximum stack count (0 = unlimited)
@export var max_stacks: int = 0

@export_group("Collection")
## Team that can collect (use empty for any)
@export var collectable_by_team: String = "player"

## Auto-collect when in range
@export var auto_collect: bool = true

## Collection range (if auto-collect)
@export var collection_range: float = 30.0

@export_group("Behavior")
## Whether power-up expires if not collected
@export var has_lifetime: bool = true

## Lifetime before expiration (seconds)
@export var lifetime: float = 10.0

## Whether to blink when expiring
@export var blink_when_expiring: bool = true

## Time before expiration to start blinking
@export var blink_warning_time: float = 3.0

@export_group("Movement")
## Whether power-up moves toward collector (magnetic)
@export var magnetic: bool = false

## Magnetic attraction strength
@export var magnetic_strength: float = 200.0

## Magnetic activation range
@export var magnetic_range: float = 100.0

@export_group("Visual")
## Sprite to animate (NodePath)
@export var sprite_path: NodePath = NodePath("Sprite")

## Floating animation
@export var float_animation: bool = true

## Float amplitude
@export var float_amplitude: float = 10.0

## Float speed
@export var float_speed: float = 2.0

@export_group("Advanced")
## Whether to destroy after collection
@export var destroy_on_collect: bool = true

## Whether to print debug messages
@export var debug_powerup: bool = false
#endregion

#region Private Variables
## Lifetime timer
var _lifetime_timer: float = 0.0

## Duration timer (for temporary effects)
var _duration_timer: float = 0.0

## Whether currently collected
var _is_collected: bool = false

## Current stack count
var _stack_count: int = 0

## Sprite reference
var _sprite: Node2D = null

## Initial sprite position (for float animation)
var _initial_sprite_y: float = 0.0

## Float timer
var _float_timer: float = 0.0

## Area2D for collection
var _collection_area: Area2D = null

## Nearest potential collector
var _nearest_collector: Node2D = null
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	_lifetime_timer = lifetime

func component_ready() -> void:
	# Find sprite
	if not sprite_path.is_empty():
		_sprite = get_node_or_null(sprite_path)
		if _sprite:
			_initial_sprite_y = _sprite.position.y
	
	# Setup collection area
	_setup_collection_area()
	
	if debug_powerup:
		print("[PowerUpComponent] Ready - Type: %s, Value: %d" % [
			PowerUpType.keys()[powerup_type],
			value
		])

func component_process(delta: float) -> void:
	# Update lifetime
	if has_lifetime and not _is_collected:
		_lifetime_timer -= delta
		
		# Check expiration warning
		if _lifetime_timer <= blink_warning_time and _lifetime_timer > 0:
			if blink_when_expiring:
				_update_blink_effect(delta)
			
			expiring_soon.emit(_lifetime_timer)
		
		# Expire
		if _lifetime_timer <= 0:
			_expire()
			return
	
	# Update duration (for temporary effects)
	if temporary and _is_collected:
		_duration_timer -= delta
		if _duration_timer <= 0:
			_expire_effect()
	
	# Float animation
	if float_animation and _sprite and not _is_collected:
		_update_float_animation(delta)
	
	# Magnetic attraction
	if magnetic and not _is_collected:
		_update_magnetic_pull(delta)

func cleanup() -> void:
	_sprite = null
	_collection_area = null
	_nearest_collector = null
	super.cleanup()
#endregion

#region Public Methods - Collection
## Manually collect the power-up
##
## @param collector: Node that is collecting
## @returns: true if collected successfully
func collect(collector: Node) -> bool:
	if _is_collected:
		return false
	
	# Check team
	if not collectable_by_team.is_empty():
		if not collector.is_in_group(collectable_by_team):
			return false
	
	# Apply effect
	_apply_effect(collector)
	
	# Mark as collected
	_is_collected = true
	
	# Start duration timer if temporary
	if temporary:
		_duration_timer = duration
	
	# Emit signal
	collected.emit(collector, powerup_type)
	
	if debug_powerup:
		print("[PowerUpComponent] Collected by %s" % collector.name)
	
	# Destroy if configured
	if destroy_on_collect:
		await get_tree().create_timer(0.1).timeout  # Small delay for visuals
		if host:
			host.queue_free()
	
	return true
#endregion

#region Public Methods - Stacking
## Add a stack
func add_stack() -> bool:
	if not stackable:
		return false
	
	if max_stacks > 0 and _stack_count >= max_stacks:
		return false
	
	_stack_count += 1
	
	# Reset duration if temporary
	if temporary:
		_duration_timer = duration
	
	return true

## Get current stack count
func get_stack_count() -> int:
	return _stack_count
#endregion

#region Private Methods - Effects
## Apply power-up effect to collector
func _apply_effect(collector: Node) -> void:
	match powerup_type:
		PowerUpType.HEALTH:
			_apply_health_effect(collector)
		PowerUpType.AMMO:
			_apply_ammo_effect(collector)
		PowerUpType.WEAPON:
			_apply_weapon_effect(collector)
		PowerUpType.SPEED:
			_apply_speed_effect(collector)
		PowerUpType.SHIELD:
			_apply_shield_effect(collector)
		PowerUpType.SCORE:
			_apply_score_effect(collector)
		PowerUpType.CUSTOM:
			# Custom effects handled via signals
			pass

## Apply health restoration
func _apply_health_effect(collector: Node) -> void:
	# Try to find HealthComponent
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var health = host_comp.get_component("HealthComponent")
		if health and health.has_method("heal"):
			health.heal(value)
			if debug_powerup:
				print("[PowerUpComponent] Healed %s for %d" % [collector.name, value])

## Apply ammo
func _apply_ammo_effect(collector: Node) -> void:
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var weapon = host_comp.get_component("WeaponComponent")
		if weapon and weapon.has_method("add_ammo"):
			weapon.add_ammo(value)

## Apply weapon upgrade
func _apply_weapon_effect(collector: Node) -> void:
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var weapon = host_comp.get_component("WeaponComponent")
		if weapon and weapon.has_method("upgrade"):
			weapon.upgrade()

## Apply speed boost
func _apply_speed_effect(collector: Node) -> void:
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var movement = host_comp.get_component("MovementComponent")
		if movement:
			# Store original speed if first application
			if not collector.has_meta("original_speed"):
				collector.set_meta("original_speed", movement.max_speed)
			
			# Apply boost
			movement.max_speed = movement.max_speed * (1.0 + value / 100.0)

## Apply shield
func _apply_shield_effect(collector: Node) -> void:
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var health = host_comp.get_component("HealthComponent")
		if health:
			# Enable invincibility for duration
			collector.set_meta("powerup_shield", true)

## Apply score bonus
func _apply_score_effect(collector: Node) -> void:
	if collector.has_node("ComponentHost"):
		var host_comp = collector.get_node("ComponentHost")
		var score = host_comp.get_component("ScoreComponent")
		if score and score.has_method("add_score"):
			score.add_score(value)

## Expire the power-up effect
func _expire_effect() -> void:
	effect_expired.emit(powerup_type)
	
	if debug_powerup:
		print("[PowerUpComponent] Effect expired: %s" % PowerUpType.keys()[powerup_type])
	
	# Cleanup based on type
	# (e.g., restore original speed for SPEED boost)
	if temporary and destroy_on_collect and host:
		host.queue_free()

## Expire the power-up (not collected in time)
func _expire() -> void:
	if debug_powerup:
		print("[PowerUpComponent] Power-up expired without collection")
	
	if host:
		host.queue_free()
#endregion

#region Private Methods - Visuals
## Update float animation
func _update_float_animation(delta: float) -> void:
	_float_timer += delta * float_speed
	var offset = sin(_float_timer) * float_amplitude
	_sprite.position.y = _initial_sprite_y + offset

## Update blink effect
func _update_blink_effect(delta: float) -> void:
	if not _sprite:
		return
	
	var blink_speed = 10.0
	var alpha = (sin(_lifetime_timer * blink_speed) + 1.0) / 2.0
	_sprite.modulate.a = lerp(0.3, 1.0, alpha)
#endregion

#region Private Methods - Collection
## Setup collection area
func _setup_collection_area() -> void:
	# Try to find existing Area2D
	for child in host.get_children():
		if child is Area2D:
			_collection_area = child
			break
	
	if not _collection_area:
		# Create default collection area
		_collection_area = Area2D.new()
		_collection_area.name = "CollectionArea"
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = collection_range
		collision.shape = shape
		
		_collection_area.add_child(collision)
		host.add_child(_collection_area)
	
	# Connect signal
	if auto_collect:
		_collection_area.body_entered.connect(_on_body_entered)

## Handle body entering collection area
func _on_body_entered(body: Node) -> void:
	if auto_collect and not _is_collected:
		collect(body)

## Update magnetic pull toward collector
func _update_magnetic_pull(delta: float) -> void:
	# Find nearest collector
	_find_nearest_collector()
	
	if not _nearest_collector:
		return
	
	var distance = host.global_position.distance_to(_nearest_collector.global_position)
	
	if distance <= magnetic_range:
		# Pull toward collector
		var direction = (_nearest_collector.global_position - host.global_position).normalized()
		var pull_strength = magnetic_strength * (1.0 - distance / magnetic_range)
		
		host.global_position += direction * pull_strength * delta

## Find nearest potential collector
func _find_nearest_collector() -> void:
	if not _collection_area:
		return
	
	var bodies = _collection_area.get_overlapping_bodies()
	var nearest_dist = INF
	_nearest_collector = null
	
	for body in bodies:
		if collectable_by_team.is_empty() or body.is_in_group(collectable_by_team):
			var dist = host.global_position.distance_to(body.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				_nearest_collector = body
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"type": PowerUpType.keys()[powerup_type],
		"value": value,
		"collected": _is_collected,
		"lifetime_remaining": "%.2fs" % _lifetime_timer if has_lifetime else "infinite",
		"duration_remaining": "%.2fs" % _duration_timer if temporary and _is_collected else "N/A",
		"stacks": _stack_count if stackable else "N/A",
		"magnetic": magnetic,
		"nearest_collector": _nearest_collector.name if _nearest_collector else "none"
	}
#endregion
