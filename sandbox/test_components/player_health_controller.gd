## Player Controller for Health Test
##
## Demonstrates health system with movement and damage taking.

extends CharacterBody2D

#region Node References
@onready var component_host: ComponentHost = $ComponentHost
var health: HealthComponent = null
var movement: TopDownMovement = null
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	health = component_host.get_component("HealthComponent")
	movement = component_host.get_component("TopDownMovement")
	
	if not health:
		push_error("HealthComponent not found!")
		return
	
	# Connect to health signals
	health.health_changed.connect(_on_health_changed)
	health.damage_taken.connect(_on_damage_taken)
	health.died.connect(_on_died)
	health.invincibility_started.connect(_on_invincibility_started)
	health.invincibility_ended.connect(_on_invincibility_ended)
	health.health_critical.connect(_on_health_critical)
	
	print("[Player] Ready! Health: %d/%d" % [health.current_health, health.max_health])

func _physics_process(_delta: float) -> void:
	if not movement or health.is_dead():
		return
	
	_handle_input()

func _process(_delta: float) -> void:
	# Visual feedback for invincibility
	if health and health.is_invincible():
		modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
	else:
		modulate.a = 1.0
#endregion

#region Input Handling
func _handle_input() -> void:
	# Movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Also support WASD
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	
	movement.set_input_direction(input_dir)
	
	# Sprint
	if Input.is_key_pressed(KEY_SHIFT):
		movement.start_sprint()
	else:
		movement.stop_sprint()
#endregion

#region Signal Callbacks
func _on_health_changed(new_health: int, old_health: int) -> void:
	print("[Player] Health: %d -> %d" % [old_health, new_health])

func _on_damage_taken(amount: int, attacker: Node) -> void:
	var attacker_name = attacker.name if attacker else "unknown"
	print("[Player] Took %d damage from %s!" % [amount, attacker_name])

func _on_died() -> void:
	print("[Player] DIED!")
	# Stop movement
	if movement:
		movement.disable_movement()
	
	# Visual feedback
	modulate = Color(0.5, 0.5, 0.5, 0.7)

func _on_invincibility_started() -> void:
	print("[Player] Invincibility started")

func _on_invincibility_ended() -> void:
	print("[Player] Invincibility ended")

func _on_health_critical(current: int) -> void:
	print("[Player] CRITICAL HEALTH: %d" % current)
#endregion
