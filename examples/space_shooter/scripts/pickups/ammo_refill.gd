## Ammo Refill Pickup
##
## Refills ammo for secondary and special weapons.
## SECONDARY: +10, SPECIAL: +2

extends PowerUpBase

#region Constants
const SECONDARY_AMMO: int = 10
const SPECIAL_AMMO: int = 2
#endregion

func _ready() -> void:
	pickup_value = SECONDARY_AMMO + SPECIAL_AMMO
	despawn_time = 12.0
	pickup_color = NEON_YELLOW

	super._ready()

	# Create visual
	_create_ammo_visual()

	# Create collision
	create_collision_shape(Vector2(28, 28))

	print("[AmmoRefill] Created - SECONDARY +%d, SPECIAL +%d" % [SECONDARY_AMMO, SPECIAL_AMMO])

func _create_ammo_visual() -> void:
	var visual_container = Node2D.new()
	visual_container.name = "Visual"
	add_child(visual_container)

	# Ammo box (yellow rect)
	var box = ColorRect.new()
	box.size = Vector2(28, 22)
	box.position = Vector2(-14, -11)
	box.color = NEON_YELLOW
	visual_container.add_child(box)

	# Ammo symbol (bullets)
	var bullet1 = ColorRect.new()
	bullet1.size = Vector2(4, 12)
	bullet1.position = Vector2(-8, -6)
	bullet1.color = Color(0.1, 0.1, 0.1)
	visual_container.add_child(bullet1)

	var bullet2 = ColorRect.new()
	bullet2.size = Vector2(4, 12)
	bullet2.position = Vector2(-1, -6)
	bullet2.color = Color(0.1, 0.1, 0.1)
	visual_container.add_child(bullet2)

	var bullet3 = ColorRect.new()
	bullet3.size = Vector2(4, 12)
	bullet3.position = Vector2(6, -6)
	bullet3.color = Color(0.1, 0.1, 0.1)
	visual_container.add_child(bullet3)

	# Glow
	var glow = ColorRect.new()
	glow.size = Vector2(36, 30)
	glow.position = Vector2(-18, -15)
	glow.color = Color(NEON_YELLOW, 0.3)
	glow.z_index = -1
	visual_container.add_child(glow)

	visual_node = visual_container

	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(visual_container, "scale", Vector2(1.1, 1.1), 0.6)
	tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.6)

func apply_effect(player: Node) -> void:
	# Find weapon manager
	var weapon_manager = null

	# Try to access weapon_manager variable directly from PlayerController
	if "weapon_manager" in player:
		weapon_manager = player.weapon_manager
	# Try common node paths
	elif player.has_node("PlayerHost/WeaponSlotManager"):
		weapon_manager = player.get_node("PlayerHost/WeaponSlotManager")
	elif player.has_node("WeaponSlotManager"):
		weapon_manager = player.get_node("WeaponSlotManager")
	else:
		# Search in PlayerHost children
		if player.has_node("PlayerHost"):
			var host = player.get_node("PlayerHost")
			for child in host.get_children():
				if child.has_method("refill_ammo"):
					weapon_manager = child
					break

	if weapon_manager and weapon_manager.has_method("add_ammo"):
		# WeaponSlotManager slots: 0=PRIMARY, 1=SECONDARY, 2=SPECIAL
		var secondary_added = weapon_manager.add_ammo(1, SECONDARY_AMMO)  # Slot 1 = SECONDARY
		var special_added = weapon_manager.add_ammo(2, SPECIAL_AMMO)      # Slot 2 = SPECIAL

		print("[AmmoRefill] Refilled ammo - SECONDARY +%d, SPECIAL +%d" % [secondary_added, special_added])
	else:
		push_warning("[AmmoRefill] Could not find weapon_manager with add_ammo method")
		print("[AmmoRefill] Player structure: ", player.name)
		if "weapon_manager" in player:
			print("[AmmoRefill] Found weapon_manager variable: ", player.weapon_manager)
