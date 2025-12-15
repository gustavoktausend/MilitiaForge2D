## Basic Enemy AI
##
## Simple AI that moves and dies when health reaches zero.

extends CharacterBody2D

var health: HealthComponent
var movement: BoundedMovement

func _ready() -> void:
	await get_tree().process_frame
	
	health = $ComponentHost.get_component("HealthComponent")
	movement = $ComponentHost.get_component("BoundedMovement")
	
	if health:
		health.died.connect(_on_died)
	
	if movement:
		# Random initial velocity
		movement.velocity = Vector2(
			randf_range(-1, 1),
			randf_range(0.5, 1)
		).normalized() * movement.max_speed

func _on_died() -> void:
	# Simple explosion effect (scale up then destroy)
	var tween = create_tween()
	tween.tween_property($Sprite, "scale", Vector2(2, 2), 0.2)
	tween.tween_property($Sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
