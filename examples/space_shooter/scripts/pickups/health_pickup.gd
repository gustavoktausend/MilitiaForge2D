## Health Pickup
##
## Restores 30 HP to the player when collected.
## Common drop (40% of power-up drops).

extends PowerUpBase

#region Constants
const HEAL_AMOUNT: int = 30
#endregion

func _ready() -> void:
	pickup_value = HEAL_AMOUNT
	despawn_time = 15.0
	pickup_color = NEON_GREEN

	super._ready()

	# Create visual
	_create_health_visual()

	# Create collision
	create_collision_shape(Vector2(24, 24))

	print("[HealthPickup] Created - heals %d HP" % HEAL_AMOUNT)

func _create_health_visual() -> void:
	# Cruz verde neon (Green cross)
	var visual_container = Node2D.new()
	visual_container.name = "Visual"
	add_child(visual_container)

	# Vertical bar of cross
	var vertical = ColorRect.new()
	vertical.size = Vector2(8, 24)
	vertical.position = Vector2(-4, -12)
	vertical.color = NEON_GREEN
	visual_container.add_child(vertical)

	# Horizontal bar of cross
	var horizontal = ColorRect.new()
	horizontal.size = Vector2(24, 8)
	horizontal.position = Vector2(-12, -4)
	horizontal.color = NEON_GREEN
	visual_container.add_child(horizontal)

	# Glow effect
	var glow = ColorRect.new()
	glow.size = Vector2(32, 32)
	glow.position = Vector2(-16, -16)
	glow.color = Color(NEON_GREEN, 0.3)
	glow.z_index = -1
	visual_container.add_child(glow)

	visual_node = visual_container

	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(visual_container, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.5)

func apply_effect(player: Node) -> void:
	# Find health component
	var health_component = null

	# Try to access health variable directly from PlayerController
	if "health" in player:
		health_component = player.health
	# Try common node paths
	elif player.has_node("PlayerHost/Health"):
		health_component = player.get_node("PlayerHost/Health")
	elif player.has_node("Health"):
		health_component = player.get_node("Health")
	else:
		# Search for HealthComponent in PlayerHost children
		if player.has_node("PlayerHost"):
			var host = player.get_node("PlayerHost")
			for child in host.get_children():
				if child.has_method("heal"):
					health_component = child
					break

	if health_component and health_component.has_method("heal"):
		var healed = health_component.heal(HEAL_AMOUNT)
		print("[HealthPickup] Healed player for %d HP (actual: %d)" % [HEAL_AMOUNT, healed])
	else:
		push_warning("[HealthPickup] Could not find health component on player")
		print("[HealthPickup] Player structure: ", player.name)
		if "health" in player:
			print("[HealthPickup] Found health variable: ", player.health)
		print("[HealthPickup] Children: ", player.get_children())
