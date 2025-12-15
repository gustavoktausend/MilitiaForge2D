## Projectile Component
##
## Manages projectile behavior including movement patterns, damage, and lifetime.
## Works with BoundedMovement for boundary handling and Hitbox for damage dealing.
##
## Features:
## - Multiple movement patterns (straight, wave, homing, spiral)
## - Configurable damage and lifetime
## - Team system (player vs enemy projectiles)
## - Pierce functionality (hit multiple targets)
## - Auto-destruction on boundaries
## - Target tracking for homing
##
## @tutorial(Combat System): res://docs/components/combat.md

class_name ProjectileComponent extends Component

#region Signals
## Emitted when projectile hits a target
signal projectile_hit(target: Node, damage: int)

## Emitted when projectile is destroyed
signal projectile_destroyed(reason: String)
#endregion

#region Enums
## Movement patterns for projectiles
enum ProjectilePattern {
	STRAIGHT,      ## Move in straight line
	WAVE,          ## Sine wave movement
	HOMING,        ## Track and follow target
	SPIRAL,        ## Spiral movement
	ACCELERATING   ## Accelerate over time
}

## Team affiliation for collision filtering
enum Team {
	PLAYER,   ## Player projectiles (hit enemies)
	ENEMY,    ## Enemy projectiles (hit player)
	NEUTRAL   ## Hits everyone
}
#endregion

#region Exports
@export_group("Projectile")
## Damage dealt on hit
@export var damage: int = 10

## Projectile speed
@export var speed: float = 400.0

## Direction to move (normalized automatically)
@export var direction: Vector2 = Vector2.UP

## Team affiliation
@export var team: Team = Team.PLAYER

@export_group("Behavior")
## Movement pattern
@export var pattern: ProjectilePattern = ProjectilePattern.STRAIGHT

## Lifetime in seconds (0 = infinite)
@export var lifetime: float = 5.0

## Whether projectile can hit multiple targets
@export var pierce: bool = false

## Maximum pierce count (0 = infinite if pierce is true)
@export var max_pierce_count: int = 0

## Whether to destroy on hit (ignored if pierce is true)
@export var destroy_on_hit: bool = true

@export_group("Pattern Settings")
## Wave amplitude (for WAVE pattern)
@export var wave_amplitude: float = 50.0

## Wave frequency (for WAVE pattern)
@export var wave_frequency: float = 5.0

## Acceleration rate (for ACCELERATING pattern)
@export var acceleration: float = 100.0

## Spiral radius (for SPIRAL pattern)
@export var spiral_radius: float = 30.0

## Spiral speed (for SPIRAL pattern)
@export var spiral_speed: float = 3.0

## Target for homing (NodePath or set programmatically)
@export var homing_target_path: NodePath = NodePath()

## Homing turn speed (degrees per second)
@export var homing_turn_speed: float = 180.0

@export_group("Advanced")
## Whether to auto-setup hitbox
@export var auto_setup_hitbox: bool = true

## Whether to auto-setup bounded movement for cleanup
@export var auto_setup_bounded_movement: bool = true

## Whether to print debug messages
@export var debug_projectile: bool = false
#endregion

#region Private Variables
## Current lifetime timer
var _lifetime_timer: float = 0.0

## Current pierce count
var _pierce_count: int = 0

## Homing target node
var _homing_target: Node2D = null

## Initial direction (for pattern calculations)
var _initial_direction: Vector2 = Vector2.UP

## Pattern offset (for wave and spiral)
var _pattern_offset: float = 0.0

## Current speed (for acceleration)
var _current_speed: float = 0.0

## Movement component reference
var _movement: Component = null

## Hitbox reference
var _hitbox: Hitbox = null

## Targets already hit (for pierce tracking)
var _hit_targets: Array[Node] = []
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Normalize direction
	if direction.length() > 0:
		direction = direction.normalized()
		_initial_direction = direction
	
	_current_speed = speed
	_lifetime_timer = lifetime

func component_ready() -> void:
	# Get or setup movement component
	_movement = host.get_component("MovementComponent")
	
	if not _movement and auto_setup_bounded_movement:
		_setup_bounded_movement()
	
	# Get or setup hitbox
	_find_or_create_hitbox()
	
	# Find homing target if path is set
	if not homing_target_path.is_empty():
		_homing_target = get_node_or_null(homing_target_path)
	
	# Apply initial velocity
	if _movement:
		_movement.velocity = direction * _current_speed
	
	if debug_projectile:
		print("[ProjectileComponent] Ready - Damage: %d, Speed: %.1f, Pattern: %s" % [
			damage, speed, ProjectilePattern.keys()[pattern]
		])

func component_process(delta: float) -> void:
	# Update lifetime
	if lifetime > 0:
		_lifetime_timer -= delta
		if _lifetime_timer <= 0:
			_destroy_projectile("lifetime_expired")
			return
	
	# Update movement pattern
	_update_pattern(delta)

func cleanup() -> void:
	_homing_target = null
	_hit_targets.clear()
	super.cleanup()
#endregion

#region Movement Patterns
## Update projectile movement based on pattern
func _update_pattern(delta: float) -> void:
	if not _movement:
		return
	
	match pattern:
		ProjectilePattern.STRAIGHT:
			_update_straight()
			
		ProjectilePattern.WAVE:
			_update_wave(delta)
			
		ProjectilePattern.HOMING:
			_update_homing(delta)
			
		ProjectilePattern.SPIRAL:
			_update_spiral(delta)
			
		ProjectilePattern.ACCELERATING:
			_update_accelerating(delta)

## Straight line movement
func _update_straight() -> void:
	_movement.velocity = direction * _current_speed

## Wave pattern movement
func _update_wave(delta: float) -> void:
	_pattern_offset += delta * wave_frequency
	
	# Calculate perpendicular direction for wave
	var perpendicular = Vector2(-direction.y, direction.x)
	var wave_offset = sin(_pattern_offset) * wave_amplitude
	
	# Combine forward movement with wave
	var wave_direction = direction + perpendicular.normalized() * (wave_offset / 100.0)
	_movement.velocity = wave_direction.normalized() * _current_speed

## Homing movement
func _update_homing(delta: float) -> void:
	if not _homing_target or not is_instance_valid(_homing_target):
		# No target, move straight
		_movement.velocity = direction * _current_speed
		return
	
	# Calculate direction to target
	var to_target = (_homing_target.global_position - host.global_position).normalized()
	
	# Rotate current direction towards target
	var angle_diff = direction.angle_to(to_target)
	var max_rotation = deg_to_rad(homing_turn_speed) * delta
	
	if abs(angle_diff) < max_rotation:
		direction = to_target
	else:
		direction = direction.rotated(sign(angle_diff) * max_rotation)
	
	_movement.velocity = direction * _current_speed

## Spiral pattern movement
func _update_spiral(delta: float) -> void:
	_pattern_offset += delta * spiral_speed
	
	# Calculate spiral offset
	var perpendicular = Vector2(-direction.y, direction.x)
	var spiral_x = cos(_pattern_offset) * spiral_radius
	var spiral_y = sin(_pattern_offset) * spiral_radius
	
	var spiral_direction = direction + perpendicular.normalized() * (spiral_x / 100.0)
	_movement.velocity = spiral_direction.normalized() * _current_speed

## Accelerating movement
func _update_accelerating(delta: float) -> void:
	_current_speed += acceleration * delta
	_movement.velocity = direction * _current_speed
#endregion

#region Public Methods
## Set the projectile direction
func set_direction(new_direction: Vector2) -> void:
	if new_direction.length() > 0:
		direction = new_direction.normalized()
		_initial_direction = direction
		
		if _movement:
			_movement.velocity = direction * _current_speed

## Set homing target
func set_homing_target(target: Node2D) -> void:
	_homing_target = target
	
	if debug_projectile:
		print("[ProjectileComponent] Homing target set: %s" % target.name)

## Get current velocity
func get_velocity() -> Vector2:
	if _movement:
		return _movement.velocity
	return Vector2.ZERO

## Force destroy the projectile
func destroy() -> void:
	_destroy_projectile("manual")
#endregion

#region Hit Handling
## Called when hitbox hits something
func _on_hitbox_hit(target: Node, hit_damage: int) -> void:
	# Check if already hit (for pierce)
	if pierce and target in _hit_targets:
		return
	
	# Track hit
	_hit_targets.append(target)
	_pierce_count += 1
	
	projectile_hit.emit(target, hit_damage)
	
	if debug_projectile:
		print("[ProjectileComponent] Hit %s for %d damage (pierce count: %d)" % [
			target.name, hit_damage, _pierce_count
		])
	
	# Check if should destroy
	if not pierce and destroy_on_hit:
		_destroy_projectile("hit_target")
	elif pierce and max_pierce_count > 0 and _pierce_count >= max_pierce_count:
		_destroy_projectile("max_pierce_reached")
#endregion

#region Private Methods
## Find or create hitbox
func _find_or_create_hitbox() -> void:
	# Try to find existing hitbox in host hierarchy
	for child in host.get_children():
		if child is Hitbox:
			_hitbox = child
			break
	
	# Create if needed and auto-setup enabled
	if not _hitbox and auto_setup_hitbox:
		_create_hitbox()
	
	# Connect to hitbox
	if _hitbox:
		_hitbox.damage = damage
		_hitbox.hit_landed.connect(_on_hitbox_hit)

## Create a default hitbox
func _create_hitbox() -> void:
	var hitbox = Hitbox.new()
	hitbox.name = "ProjectileHitbox"
	hitbox.damage = damage
	hitbox.hit_once_per_target = not pierce
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0  # Default radius
	collision.shape = shape
	hitbox.add_child(collision)
	
	host.add_child(hitbox)
	_hitbox = hitbox
	
	if debug_projectile:
		print("[ProjectileComponent] Auto-created hitbox")

## Setup bounded movement for auto-cleanup
func _setup_bounded_movement() -> void:
	var bounded = BoundedMovement.new()
	bounded.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
	bounded.max_speed = speed * 2  # Allow some overhead
	bounded.destroy_host_on_boundary = true
	
	host.add_component(bounded)
	_movement = bounded
	
	bounded.destroyed_by_boundary.connect(func(edge):
		_destroy_projectile("boundary")
	)
	
	if debug_projectile:
		print("[ProjectileComponent] Auto-setup BoundedMovement")

## Destroy the projectile
func _destroy_projectile(reason: String) -> void:
	projectile_destroyed.emit(reason)
	
	if debug_projectile:
		print("[ProjectileComponent] Destroyed: %s" % reason)
	
	if host:
		host.queue_free()
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"damage": damage,
		"speed": _current_speed,
		"pattern": ProjectilePattern.keys()[pattern],
		"team": Team.keys()[team],
		"lifetime_remaining": "%.2fs" % _lifetime_timer if lifetime > 0 else "infinite",
		"pierce_count": "%d/%d" % [_pierce_count, max_pierce_count] if pierce else "disabled",
		"direction": "%.2f, %.2f" % [direction.x, direction.y],
		"has_target": _homing_target != null if pattern == ProjectilePattern.HOMING else "N/A"
	}
#endregion
