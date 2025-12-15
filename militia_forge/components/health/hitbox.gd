## Hitbox Component
##
## Area that deals damage to Hurtbox components.
## Can be configured to deal damage once or continuously.
##
## Usage:
## 1. Add as child of an Area2D node
## 2. Set damage amount and type
## 3. Configure collision layers/masks to hit Hurtboxes
## 4. Hitbox will automatically deal damage on contact
##
## @tutorial(Health System): res://docs/components/health.md

class_name Hitbox extends Area2D

#region Signals
## Emitted when this hitbox successfully deals damage
signal hit_landed(target: Node, damage: int)

## Emitted when hitbox is activated
signal hitbox_activated()

## Emitted when hitbox is deactivated
signal hitbox_deactivated()
#endregion

#region Exports
@export_group("Hitbox Settings")
## Amount of damage to deal
@export var damage: int = 10

## Whether this hitbox is currently active
@export var active: bool = true

## Whether hitbox only deals damage once per target
@export var hit_once_per_target: bool = false

## Whether hitbox auto-deactivates after hitting once
@export var one_shot: bool = false

@export_group("Knockback")
## Whether to apply knockback
@export var apply_knockback: bool = false

## Knockback force
@export var knockback_force: float = 200.0

## Knockback direction (if zero, uses direction from attacker to target)
@export var knockback_direction: Vector2 = Vector2.ZERO

@export_group("Advanced")
## Lifetime of hitbox (0 = infinite)
@export var lifetime: float = 0.0

## Delay before hitbox becomes active
@export var activation_delay: float = 0.0

## Whether to print debug messages
@export var debug_hitbox: bool = false
#endregion

#region Private Variables
## Reference to the owner entity (who is attacking)
var _owner_node: Node = null

## Targets that have already been hit (for hit_once_per_target)
var _hit_targets: Array[Node] = []

## Lifetime timer
var _lifetime_timer: float = 0.0

## Activation delay timer
var _activation_timer: float = 0.0

## Whether hitbox has been activated
var _is_activated: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	# Set initial state
	if activation_delay > 0:
		active = false
		_activation_timer = activation_delay
	else:
		_activate()
	
	# Set lifetime if specified
	if lifetime > 0:
		_lifetime_timer = lifetime
	
	# Find owner
	_find_owner()
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	
	if debug_hitbox:
		print("[Hitbox] Ready - Damage: %d, Active: %s" % [damage, active])

func _process(delta: float) -> void:
	# Update activation delay
	if not _is_activated and _activation_timer > 0:
		_activation_timer -= delta
		if _activation_timer <= 0:
			_activate()
	
	# Update lifetime
	if lifetime > 0 and _is_activated:
		_lifetime_timer -= delta
		if _lifetime_timer <= 0:
			_expire()
#endregion

#region Damage Dealing
## Called when an area enters this hitbox.
func _on_area_entered(area: Area2D) -> void:
	if not active or not _is_activated:
		return
	
	# Check if the area is a Hurtbox
	if not area is Hurtbox:
		return
	
	var hurtbox = area as Hurtbox
	var target = hurtbox.get_parent()
	
	# Check if target is valid
	if not target:
		return
	
	# Check if already hit this target
	if hit_once_per_target and target in _hit_targets:
		return
	
	# Deal damage (Hurtbox handles this)
	# We just emit our signal for tracking
	hit_landed.emit(target, damage)
	
	# Track hit target
	if hit_once_per_target:
		_hit_targets.append(target)
	
	# Apply knockback if enabled
	if apply_knockback:
		_apply_knockback_to_target(target)
	
	# Deactivate if one-shot
	if one_shot:
		deactivate()
	
	if debug_hitbox:
		print("[Hitbox] Hit %s for %d damage" % [target.name, damage])

## Called by Hurtbox when hit lands successfully.
func on_hit_landed(target: Node) -> void:
	# This is called by the Hurtbox to notify us
	# Can be used for additional effects, sounds, etc.
	pass
#endregion

#region Public Methods
## Activate this hitbox.
func activate() -> void:
	if _is_activated:
		return
	
	_activate()

## Deactivate this hitbox.
func deactivate() -> void:
	if not _is_activated:
		return
	
	active = false
	_is_activated = false
	hitbox_deactivated.emit()
	
	if debug_hitbox:
		print("[Hitbox] Deactivated")

## Reset hitbox (clear hit targets, reactivate if needed).
func reset() -> void:
	_hit_targets.clear()
	
	if not active and not one_shot:
		activate()

## Set the damage amount.
func set_damage(new_damage: int) -> void:
	damage = new_damage

## Get the owner node (entity using this hitbox).
func get_owner_node() -> Node:
	return _owner_node

## Check if hitbox is currently active.
func is_active() -> bool:
	return active and _is_activated
#endregion

#region Private Methods
## Find the owner entity.
func _find_owner() -> void:
	# The owner is typically the parent or grandparent
	var current = get_parent()
	
	while current:
		# Skip Area2D nodes
		if not current is Area2D:
			_owner_node = current
			return
		
		current = current.get_parent()

## Activate the hitbox.
func _activate() -> void:
	active = true
	_is_activated = true
	monitoring = true
	monitorable = true
	hitbox_activated.emit()
	
	if debug_hitbox:
		print("[Hitbox] Activated")

## Expire and remove the hitbox.
func _expire() -> void:
	if debug_hitbox:
		print("[Hitbox] Expired (lifetime reached)")
	
	queue_free()

## Apply knockback to target.
func _apply_knockback_to_target(target: Node) -> void:
	# Try to find MovementComponent
	var movement: Component = null
	
	for child in target.get_children():
		if child is ComponentHost:
			movement = child.get_component("MovementComponent")
			break
	
	if not movement:
		return
	
	# Calculate knockback direction
	var kb_dir = knockback_direction
	if kb_dir == Vector2.ZERO and _owner_node:
		# Use direction from owner to target
		kb_dir = (target.global_position - _owner_node.global_position).normalized()
	
	# Apply knockback by temporarily disabling movement and setting velocity
	movement.disable_movement()
	movement.velocity = kb_dir * knockback_force
	
	# Re-enable after short delay
	await get_tree().create_timer(0.2).timeout
	if movement:
		movement.enable_movement()
	
	if debug_hitbox:
		print("[Hitbox] Applied knockback: %s" % (kb_dir * knockback_force))
#endregion
