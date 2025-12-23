class_name TDProjectile extends Node2D

@onready var host: ComponentHost = $ComponentHost
@onready var projectile_component: ProjectileComponent = $ComponentHost/ProjectileComponent

var _pending_target: Node2D = null
var _pending_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	if _pending_target:
		set_target(_pending_target)
	if _pending_velocity != Vector2.ZERO:
		set_velocity(_pending_velocity)

func set_target(target: Node2D) -> void:
	if not is_inside_tree():
		_pending_target = target
		return
		
	if projectile_component:
		# If homing is enabled in component, set it
		if projectile_component.pattern == ProjectileComponent.ProjectilePattern.HOMING:
			projectile_component.set_homing_target(target)
		else:
			# Otherwise just aim at it once
			var dir = (target.global_position - global_position).normalized()
			projectile_component.set_direction(dir)

func set_velocity(velocity: Vector2) -> void:
	if not is_inside_tree():
		_pending_velocity = velocity
		return

	if projectile_component:
		projectile_component.speed = velocity.length()
		projectile_component.set_direction(velocity.normalized())
