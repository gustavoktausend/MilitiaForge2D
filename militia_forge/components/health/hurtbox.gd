## Hurtbox Component
##
## Area that can receive damage from Hitbox components.
## Automatically connects to HealthComponent and applies damage.
##
## Usage:
## 1. Add as child of an Area2D node
## 2. Configure collision layers/masks
## 3. HealthComponent will automatically receive damage from Hitboxes
##
## @tutorial(Health System): res://docs/components/health.md

class_name Hurtbox extends Area2D

#region Signals
## Emitted when this hurtbox is hit by a hitbox
signal hit_received(hitbox: Hitbox, damage: int)
#endregion

#region Exports
@export_group("Hurtbox Settings")
## Whether this hurtbox is currently active
@export var active: bool = true

## Visual feedback when hit (optional)
@export var hit_flash_enabled: bool = false

## Duration of hit flash effect (in seconds)
@export var hit_flash_duration: float = 0.1

## Whether to print debug messages
@export var debug_hurtbox: bool = false
#endregion

#region Private Variables
## Reference to the host's HealthComponent
var _health_component: HealthComponent = null

## Reference to ComponentHost
var _component_host: ComponentHost = null

## Timer for hit flash effect
var _flash_timer: float = 0.0

## Original modulate color (for flash effect)
var _original_modulate: Color = Color.WHITE

## Node to apply visual effects to (usually a Sprite or ColorRect)
var _visual_node: Node2D = null
#endregion

#region Lifecycle
func _ready() -> void:
	# Connect to area entered
	area_entered.connect(_on_area_entered)
	
	# Find ComponentHost and HealthComponent
	_find_health_component()
	
	# Find visual node for effects
	_find_visual_node()
	
	if debug_hurtbox:
		print("[Hurtbox] Ready on %s" % get_parent().name)

func _process(delta: float) -> void:
	# Update hit flash
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_reset_visual()
#endregion

#region Damage Handling
## Called when an area enters this hurtbox.
func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	
	# Check if the area is a Hitbox
	if not area is Hitbox:
		return
	
	var hitbox = area as Hitbox
	
	# Check if hitbox is active
	if not hitbox.active:
		return
	
	# Apply damage if we have a health component
	if _health_component and _health_component.is_alive():
		var damage = hitbox.damage
		var attacker = hitbox.get_owner_node()
		
		var actual_damage = _health_component.take_damage(damage, attacker)
		
		if actual_damage > 0:
			# Visual feedback
			if hit_flash_enabled:
				_trigger_hit_flash()
			
			# Emit signal
			hit_received.emit(hitbox, actual_damage)
			
			# Notify hitbox
			hitbox.on_hit_landed(get_parent())
			
			if debug_hurtbox:
				print("[Hurtbox] Received %d damage from %s" % [actual_damage, hitbox.name])
#endregion

#region Public Methods
## Enable this hurtbox.
func enable() -> void:
	active = true
	monitoring = true
	monitorable = true

## Disable this hurtbox.
func disable() -> void:
	active = false
	monitoring = false
	monitorable = false

## Check if hurtbox is currently active.
func is_active() -> bool:
	return active
#endregion

#region Private Methods
## Find the HealthComponent in the hierarchy.
func _find_health_component() -> void:
	# Search upward in the tree
	var current = get_parent()
	
	while current:
		# Check if current node has ComponentHost
		for child in current.get_children():
			if child is ComponentHost:
				_component_host = child
				_health_component = _component_host.get_component("HealthComponent")
				
				if _health_component:
					if debug_hurtbox:
						print("[Hurtbox] Found HealthComponent")
					return
		
		current = current.get_parent()
	
	if debug_hurtbox:
		push_warning("[Hurtbox] No HealthComponent found in hierarchy")

## Find visual node for effects.
func _find_visual_node() -> void:
	# Look for common visual nodes in parent
	var parent = get_parent()
	
	for child in parent.get_children():
		if child is Sprite2D or child is AnimatedSprite2D or child is ColorRect:
			_visual_node = child
			_original_modulate = _visual_node.modulate
			return

## Trigger hit flash effect.
func _trigger_hit_flash() -> void:
	if not _visual_node:
		return
	
	_visual_node.modulate = Color(1, 0.5, 0.5, 1)  # Red tint
	_flash_timer = hit_flash_duration

## Reset visual to original state.
func _reset_visual() -> void:
	if _visual_node:
		_visual_node.modulate = _original_modulate
#endregion
