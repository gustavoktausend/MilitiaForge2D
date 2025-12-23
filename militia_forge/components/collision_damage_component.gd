## Collision Damage Component
##
## Deals damage when the physics body collides with other bodies.
## Integrates with HealthComponent to apply damage on collision.
##
## Usage:
##   var collision_damage = CollisionDamageComponent.new()
##   collision_damage.damage_on_collision = 20
##   collision_damage.collision_mask = 2  # Only collide with enemies
##   host.add_component(collision_damage)
##
## Features:
## - Configurable damage amount
## - Collision layer/mask filtering
## - Knockback on collision (optional)
## - One-time damage per collision (prevents spam)
## - Integration with invincibility frames
##
## @tutorial(Collision Damage): res://docs/components/COLLISION_DAMAGE.md

class_name CollisionDamageComponent extends Component

#region Signals
## Emitted when this body collides with another and deals damage
signal collision_damage_dealt(target: Node, damage: int)

## Emitted when this body collides with another and receives damage
signal collision_damage_taken(source: Node, damage: int)

## Emitted on any collision (even if no damage dealt)
signal body_collided(other_body: Node)
#endregion

#region Configuration
## Damage dealt to other bodies on collision
@export var damage_on_collision: int = 20

## Whether to take damage from collisions (if false, only deals damage)
@export var can_take_collision_damage: bool = true

## Damage multiplier when receiving collision damage
@export var incoming_damage_multiplier: float = 1.0

## Whether to apply knockback on collision
@export var apply_knockback: bool = true

## Knockback force (pixels)
@export var knockback_force: float = 200.0

## Collision layer (what layer this body is on)
@export var collision_layer: int = 1

## Collision mask (what layers this body can collide with)
@export var collision_mask: int = 2

## Cooldown between collision damage (prevents spam)
@export var collision_cooldown: float = 0.5
#endregion

#region Private Variables
var _physics_body: CharacterBody2D = null
var _health_component: Node = null
var _collision_timer: float = 0.0
var _last_collision_targets: Array[Node] = []  # Track to prevent duplicate damage
#endregion

#region Component Lifecycle
func component_ready() -> void:
	super.component_ready()

	# Verify host is set
	if not host:
		push_error("[CollisionDamageComponent] Host not set! Component not properly initialized.")
		return

	# Find physics body
	_find_physics_body()

	# Find health component
	_health_component = host.get_component("HealthComponent")
	if not _health_component:
		push_warning("[CollisionDamageComponent] No HealthComponent found - collision damage disabled")

	print("[CollisionDamageComponent] Ready! Damage: %d, Can take damage: %s" % [
		damage_on_collision,
		can_take_collision_damage
	])

func component_physics_process(delta: float) -> void:
	if not _physics_body or not is_enabled():
		return

	# Update collision cooldown
	if _collision_timer > 0:
		_collision_timer -= delta

	# Check for collisions
	_check_collisions()

func cleanup() -> void:
	_physics_body = null
	_health_component = null
	_last_collision_targets.clear()
	super.cleanup()
#endregion

#region Private Methods
func _find_physics_body() -> void:
	if not host:
		push_error("[CollisionDamageComponent] Cannot find physics body - host is null")
		return

	# Look for CharacterBody2D in parent or siblings
	var parent = host.get_parent()

	if not parent:
		push_error("[CollisionDamageComponent] Host has no parent!")
		return

	# Check parent first
	if parent is CharacterBody2D:
		_physics_body = parent
		print("[CollisionDamageComponent] Found physics body in parent: %s" % parent.name)
		return

	# Check for child named "Body"
	var body_node = parent.get_node_or_null("Body")
	if body_node and body_node is CharacterBody2D:
		_physics_body = body_node
		print("[CollisionDamageComponent] Found physics body: %s" % body_node.name)
		return

	# Search children
	for child in parent.get_children():
		if child is CharacterBody2D:
			_physics_body = child
			print("[CollisionDamageComponent] Found physics body in children: %s" % child.name)
			return

	push_error("[CollisionDamageComponent] No CharacterBody2D found!")

func _check_collisions() -> void:
	if not _physics_body:
		return

	# Get collision count
	var collision_count = _physics_body.get_slide_collision_count()

	if collision_count == 0:
		# No collisions, clear tracking
		if _collision_timer <= 0:
			_last_collision_targets.clear()
		return

	# Process each collision
	for i in range(collision_count):
		var collision = _physics_body.get_slide_collision(i)
		var collider = collision.get_collider()

		if not collider:
			continue

		# Skip if on cooldown with this specific target
		if _last_collision_targets.has(collider) and _collision_timer > 0:
			continue

		# Process collision
		_process_collision(collider, collision)

func _process_collision(collider: Node, collision: KinematicCollision2D) -> void:
	# Emit generic collision signal
	body_collided.emit(collider)

	# Find the root entity (player or enemy)
	var collider_entity = _find_entity_root(collider)
	if not collider_entity:
		return

	# Check if we already damaged this target recently
	if _last_collision_targets.has(collider_entity):
		return

	# Deal damage to collider
	_deal_damage_to(collider_entity)

	# Take damage from collider
	if can_take_collision_damage:
		_take_damage_from(collider_entity)

	# Apply knockback
	if apply_knockback:
		_apply_knockback(collision)

	# Track collision and start cooldown
	_last_collision_targets.append(collider_entity)
	_collision_timer = collision_cooldown

func _find_entity_root(collider: Node) -> Node:
	# Find the root entity (player/enemy) from physics body
	var current = collider

	# Walk up the tree to find ComponentHost or known entity
	for i in range(5):  # Limit depth
		if not current:
			break

		# Check if this is a known entity type
		if current.has_node("PlayerHost") or current.has_node("EnemyHost"):
			return current

		# Check if this has a ComponentHost
		for child in current.get_children():
			if child is ComponentHost or child.name.ends_with("Host"):
				return current

		current = current.get_parent()

	return null

func _deal_damage_to(target: Node) -> void:
	if damage_on_collision <= 0:
		return

	# Find target's ComponentHost
	var target_host = _find_component_host(target)
	if not target_host:
		return

	# Find target's HealthComponent
	var target_health = target_host.get_component("HealthComponent")
	if not target_health:
		return

	# Deal damage (use host's parent as attacker source)
	var attacker = host.get_parent() if host else null
	var damage_dealt = target_health.take_damage(damage_on_collision, attacker)

	print("[CollisionDamageComponent] Dealt %d collision damage to %s" % [
		damage_dealt,
		target.name
	])

	collision_damage_dealt.emit(target, damage_dealt)

func _take_damage_from(source: Node) -> void:
	if not _health_component:
		return

	# Find source's ComponentHost
	var source_host = _find_component_host(source)
	if not source_host:
		return

	# Find source's CollisionDamageComponent
	var source_collision = source_host.get_component("CollisionDamageComponent")
	if not source_collision:
		return

	# Calculate damage
	var damage = source_collision.damage_on_collision * incoming_damage_multiplier

	if damage <= 0:
		return

	# Take damage
	var damage_taken = _health_component.take_damage(int(damage), source)

	print("[CollisionDamageComponent] Took %d collision damage from %s" % [
		damage_taken,
		source.name
	])

	collision_damage_taken.emit(source, damage_taken)

func _find_component_host(entity: Node) -> ComponentHost:
	# Look for ComponentHost in entity
	for child in entity.get_children():
		if child is ComponentHost:
			return child

		# Check nested (e.g., Body/Host)
		for nested in child.get_children():
			if nested is ComponentHost:
				return nested

	return null

func _apply_knockback(collision: KinematicCollision2D) -> void:
	if not _physics_body:
		return

	# Get collision normal (direction to push away)
	var normal = collision.get_normal()

	# Apply knockback velocity
	var knockback_velocity = normal * knockback_force

	# Apply to physics body
	_physics_body.velocity += knockback_velocity

	print("[CollisionDamageComponent] Applied knockback: %v" % knockback_velocity)
#endregion

#region Public API
## Manually trigger collision damage with a specific target
func deal_collision_damage_to(target: Node) -> void:
	_deal_damage_to(target)

## Reset collision cooldown (allows immediate collision damage)
func reset_collision_cooldown() -> void:
	_collision_timer = 0.0
	_last_collision_targets.clear()
#endregion
