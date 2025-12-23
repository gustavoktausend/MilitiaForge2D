class_name ProjectileAttackCommand extends AttackCommand

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0

func execute(source: Node2D, target: Node2D) -> bool:
	print("ATTACK CMD: Execute called. ID: %d | Source: %s | Scene: %s" % [get_instance_id(), source, projectile_scene])
	if not projectile_scene:
		if Engine.get_process_frames() % 60 == 0: # Print only once per second approx
			print("ERROR: ProjectileAttackCommand: No projectile scene assigned. (Spam throttle)")
		return false
		
	# Instantiate
	var proj = projectile_scene.instantiate()
	
	# Setup Position (Check for a specific firing point or use global center)
	var spawn_pos = source.global_position
	if source.has_method("get_firing_position"):
		spawn_pos = source.get_firing_position()
		
	proj.global_position = spawn_pos
	
	# Setup Logic (Assuming Projectile has a setup method or Component)
	# This is where we might need a Projectile contract.
	# For now, we set direction/target if the projectile script supports it.
	
	if proj.has_method("set_target"):
		proj.set_target(target)
	elif proj.has_method("set_velocity"):
		var dir = (target.global_position - spawn_pos).normalized()
		proj.set_velocity(dir * projectile_speed)
		
	# Add to scene tree (Should probably use a Spawn Manager or EventBus in future)
	source.get_tree().root.add_child(proj)
	print("ATTACK: Projectile fired from %s at %s" % [source.name, target.name])
	
	return true
