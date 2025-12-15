## Simple Weapon System for Space Shooter
##
## Simplified weapon that spawns projectiles.
## Integrates with player controller.

extends Node

#region Exports
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.2
@export var projectile_speed: float = 600.0
@export var projectile_damage: int = 10
@export var auto_fire: bool = true
@export var is_player_weapon: bool = true  # Determines projectile collision layers
#endregion

#region Private Variables
var fire_cooldown: float = 0.0
var wants_to_fire: bool = false
var projectiles_container: Node = null
#endregion

func _ready() -> void:
	# Find or create projectiles container
	call_deferred("_find_projectiles_container")

func _find_projectiles_container() -> void:
	var containers = get_tree().get_nodes_in_group("projectiles_container")
	if containers.size() > 0:
		projectiles_container = containers[0]
	else:
		# Use root as fallback
		projectiles_container = get_tree().root

func _process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta

	if auto_fire and wants_to_fire and can_fire():
		execute_fire(get_parent().global_position, Vector2.UP)

func fire(position: Vector2, direction: Vector2) -> bool:
	wants_to_fire = true

	if not can_fire():
		return false

	return execute_fire(position, direction)

func stop_fire() -> void:
	wants_to_fire = false

func can_fire() -> bool:
	return fire_cooldown <= 0 and projectile_scene != null

func execute_fire(spawn_position: Vector2, direction: Vector2) -> bool:
	if not projectile_scene:
		return false

	# Create projectile
	var projectile = projectile_scene.instantiate()

	# Set projectile properties
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.is_player_projectile = is_player_weapon  # Use weapon's setting
	projectile.global_position = spawn_position

	# Add to scene
	if projectiles_container:
		projectiles_container.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)

	# Set cooldown
	fire_cooldown = fire_rate

	return true
