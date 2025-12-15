## Particle Effect Component
##
## Manages particle effects and visual feedback.
## Generic component useful for explosions, trails, hits, and environmental effects.
##
## Features:
## - Multiple effect presets (explosion, trail, hit, sparkle, etc.)
## - One-shot or continuous effects
## - Trigger-based activation
## - Effect pooling for performance
## - Custom particle parameters
## - Integration with other components (health, damage, etc.)
##
## @tutorial(Effects): res://docs/components/effects.md

class_name ParticleEffectComponent extends Component

#region Signals
## Emitted when effect starts
signal effect_started(effect_name: String)

## Emitted when effect completes
signal effect_completed(effect_name: String)
#endregion

#region Enums
## Particle effect presets
enum EffectPreset {
	EXPLOSION,    ## Explosion burst
	HIT_FLASH,    ## Hit impact
	TRAIL,        ## Continuous trail
	SPARKLE,      ## Sparkles/stars
	SMOKE,        ## Smoke puff
	FIRE,         ## Fire/flames
	HEAL,         ## Healing effect
	POWERUP,      ## Power-up collection
	CUSTOM        ## Custom configuration
}

## Trigger types
enum TriggerType {
	MANUAL,           ## Manually triggered
	ON_DAMAGE,        ## When HealthComponent takes damage
	ON_HEAL,          ## When HealthComponent heals
	ON_DEATH,         ## When HealthComponent dies
	ON_HIT_LANDED,    ## When Hitbox lands hit
	ON_HIT_RECEIVED,  ## When Hurtbox receives hit
	ON_MOVEMENT,      ## When moving (for trails)
	ON_SPAWN          ## On ready (one-shot)
}
#endregion

#region Exports
@export_group("Effect")
## Effect preset
@export var effect_preset: EffectPreset = EffectPreset.EXPLOSION

## Particle scene (if not using preset)
@export var custom_particle_scene: PackedScene

## Whether effect is one-shot or continuous
@export var one_shot: bool = true

## Auto-destroy after one-shot completes
@export var auto_destroy: bool = false

@export_group("Trigger")
## How effect is triggered
@export var trigger_type: TriggerType = TriggerType.MANUAL

## Auto-start on ready
@export var auto_start: bool = false

@export_group("Particle Parameters")
## Number of particles
@export var amount: int = 32

## Particle lifetime
@export var lifetime: float = 1.0

## Particle speed
@export var speed_scale: float = 1.0

## Particle color
@export var particle_color: Color = Color.WHITE

## Secondary color (for gradients)
@export var secondary_color: Color = Color.TRANSPARENT

@export_group("Position")
## Offset from host
@export var position_offset: Vector2 = Vector2.ZERO

## Whether to follow host position
@export var follow_host: bool = true

@export_group("Advanced")
## Whether to use object pooling
@export var use_pooling: bool = true

## Maximum instances in pool
@export var pool_size: int = 10

## Whether to print debug messages
@export var debug_effects: bool = false
#endregion

#region Private Variables
## Current particle node
var _particle_node: GPUParticles2D = null

## Object pool
var _particle_pool: Array[GPUParticles2D] = []

## Currently active particles
var _active_particles: Array[GPUParticles2D] = []

## References to connected components
var _health_component: HealthComponent = null
var _hitbox: Hitbox = null
var _hurtbox: Hurtbox = null
var _movement: Component = null
#endregion

#region Component Lifecycle
func component_ready() -> void:
	# Create initial particle node
	_create_particle_node()
	
	# Setup triggers
	_setup_triggers()
	
	# Auto-start if configured
	if auto_start:
		play_effect()
	
	if debug_effects:
		print("[ParticleEffectComponent] Ready - Preset: %s, Trigger: %s" % [
			EffectPreset.keys()[effect_preset],
			TriggerType.keys()[trigger_type]
		])

func cleanup() -> void:
	# Clean up pool
	for particle in _particle_pool:
		if is_instance_valid(particle):
			particle.queue_free()
	
	_particle_pool.clear()
	_active_particles.clear()
	
	super.cleanup()
#endregion

#region Public Methods - Control
## Play the effect
func play_effect() -> void:
	var particle = _get_particle_instance()
	
	if not particle:
		return
	
	# Position
	if follow_host and host:
		particle.global_position = host.global_position + position_offset
	
	# Start emitting
	particle.emitting = true
	particle.restart()
	
	# Track if one-shot
	if one_shot:
		_track_oneshot(particle)
	
	effect_started.emit(EffectPreset.keys()[effect_preset])
	
	if debug_effects:
		print("[ParticleEffectComponent] Effect played")

## Stop the effect
func stop_effect() -> void:
	if _particle_node:
		_particle_node.emitting = false

## Is effect currently playing
func is_playing() -> bool:
	return _particle_node != null and _particle_node.emitting
#endregion

#region Private Methods - Particle Creation
## Create particle node based on preset or custom scene
func _create_particle_node() -> void:
	if custom_particle_scene:
		var instance = custom_particle_scene.instantiate()
		if instance is GPUParticles2D:
			_particle_node = instance
	else:
		_particle_node = _create_preset_particles()
	
	if _particle_node:
		# Add to host or scene
		if follow_host and host:
			host.add_child(_particle_node)
			_particle_node.position = position_offset
		else:
			get_tree().root.add_child(_particle_node)
			_particle_node.global_position = host.global_position if host else Vector2.ZERO
		
		# Add to pool if using pooling
		if use_pooling:
			_particle_pool.append(_particle_node)

## Create particles based on preset
func _create_preset_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "ParticleEffect"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = one_shot
	particles.speed_scale = speed_scale
	particles.emitting = false
	
	# Create process material
	var material = ParticleProcessMaterial.new()
	
	# Configure based on preset
	match effect_preset:
		EffectPreset.EXPLOSION:
			_configure_explosion(material)
		EffectPreset.HIT_FLASH:
			_configure_hit_flash(material)
		EffectPreset.TRAIL:
			_configure_trail(material)
		EffectPreset.SPARKLE:
			_configure_sparkle(material)
		EffectPreset.SMOKE:
			_configure_smoke(material)
		EffectPreset.FIRE:
			_configure_fire(material)
		EffectPreset.HEAL:
			_configure_heal(material)
		EffectPreset.POWERUP:
			_configure_powerup(material)
	
	particles.process_material = material
	
	return particles

## Configure explosion preset
func _configure_explosion(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = particle_color

## Configure hit flash preset
func _configure_hit_flash(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = particle_color

## Configure trail preset
func _configure_trail(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, 1, 0)
	material.spread = 10.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.2
	material.scale_max = 0.5
	material.color = particle_color

## Configure sparkle preset
func _configure_sparkle(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3
	material.color = particle_color

## Configure smoke preset
func _configure_smoke(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.color = Color(0.5, 0.5, 0.5, 0.7)

## Configure fire preset
func _configure_fire(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 40.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, -30, 0)
	material.color = Color(1, 0.5, 0, 1)

## Configure heal preset
func _configure_heal(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, -30, 0)
	material.color = Color(0, 1, 0.5, 1)

## Configure power-up preset
func _configure_powerup(material: ParticleProcessMaterial) -> void:
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, -40, 0)
	material.color = particle_color
#endregion

#region Private Methods - Pooling
## Get particle instance from pool or create new
func _get_particle_instance() -> GPUParticles2D:
	# Try to reuse from pool
	if use_pooling and _particle_pool.size() > 0:
		for particle in _particle_pool:
			if is_instance_valid(particle) and not particle.emitting:
				return particle
	
	# Create new if pool empty or not using pooling
	if not use_pooling or _particle_pool.size() < pool_size:
		_create_particle_node()
		return _particle_node
	
	return null

## Track one-shot particle completion
func _track_oneshot(particle: GPUParticles2D) -> void:
	_active_particles.append(particle)
	
	# Wait for completion
	await get_tree().create_timer(lifetime).timeout
	
	effect_completed.emit(EffectPreset.keys()[effect_preset])
	_active_particles.erase(particle)
	
	# Auto-destroy if configured
	if auto_destroy and host:
		host.queue_free()
#endregion

#region Private Methods - Triggers
## Setup trigger connections
func _setup_triggers() -> void:
	if not host or trigger_type == TriggerType.MANUAL:
		return
	
	match trigger_type:
		TriggerType.ON_DAMAGE:
			_connect_health_damage()
		TriggerType.ON_HEAL:
			_connect_health_heal()
		TriggerType.ON_DEATH:
			_connect_health_death()
		TriggerType.ON_HIT_LANDED:
			_connect_hitbox()
		TriggerType.ON_HIT_RECEIVED:
			_connect_hurtbox()
		TriggerType.ON_MOVEMENT:
			_connect_movement()
		TriggerType.ON_SPAWN:
			# Already handled by auto_start
			pass

## Connect to HealthComponent damage
func _connect_health_damage() -> void:
	_health_component = host.get_component("HealthComponent")
	if _health_component:
		_health_component.damage_taken.connect(func(_amount, _attacker): play_effect())

## Connect to HealthComponent heal
func _connect_health_heal() -> void:
	_health_component = host.get_component("HealthComponent")
	if _health_component:
		_health_component.healed.connect(func(_amount): play_effect())

## Connect to HealthComponent death
func _connect_health_death() -> void:
	_health_component = host.get_component("HealthComponent")
	if _health_component:
		_health_component.died.connect(func(): play_effect())

## Connect to Hitbox
func _connect_hitbox() -> void:
	# Find hitbox in host hierarchy
	for child in host.get_children():
		if child is Hitbox:
			_hitbox = child
			_hitbox.hit_landed.connect(func(_target, _damage): play_effect())
			break

## Connect to Hurtbox
func _connect_hurtbox() -> void:
	# Find hurtbox in host hierarchy
	for child in host.get_children():
		if child is Hurtbox:
			_hurtbox = child
			# Hurtbox doesn't have direct signal, connect to HealthComponent
			_connect_health_damage()
			break

## Connect to MovementComponent
func _connect_movement() -> void:
	_movement = host.get_component("MovementComponent")
	if _movement:
		# For trails, enable continuous emission when moving
		_movement.movement_started.connect(func():
			if _particle_node:
				_particle_node.emitting = true
		)
		_movement.movement_stopped.connect(func():
			if _particle_node:
				_particle_node.emitting = false
		)
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"preset": EffectPreset.keys()[effect_preset],
		"trigger": TriggerType.keys()[trigger_type],
		"playing": is_playing(),
		"one_shot": one_shot,
		"pool_size": _particle_pool.size() if use_pooling else "disabled",
		"active": _active_particles.size()
	}
#endregion
