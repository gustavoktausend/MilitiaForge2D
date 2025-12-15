## Simple Enemy for Health Test
##
## Enemy that moves and deals damage on contact.

extends CharacterBody2D

#region Exports
@export var move_speed: float = 50.0
@export var wander_radius: float = 200.0
@export var direction_change_interval: float = 2.0
#endregion

#region Private Variables
var _direction: Vector2 = Vector2.ZERO
var _spawn_position: Vector2 = Vector2.ZERO
var _direction_timer: float = 0.0
#endregion

#region Lifecycle
func _ready() -> void:
	_spawn_position = global_position
	_change_direction()

func _physics_process(delta: float) -> void:
	# Update direction timer
	_direction_timer -= delta
	if _direction_timer <= 0:
		_change_direction()
	
	# Move
	velocity = _direction * move_speed
	move_and_slide()
	
	# Stay within wander radius
	if global_position.distance_to(_spawn_position) > wander_radius:
		_direction = (_spawn_position - global_position).normalized()
#endregion

#region Private Methods
func _change_direction() -> void:
	# Random direction
	_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()
	
	_direction_timer = direction_change_interval
#endregion
