## Player Controller for Input Test
##
## Demonstrates InputComponent usage with movement and actions.

extends CharacterBody2D

#region Node References
@onready var component_host: ComponentHost = $ComponentHost
var input_comp: InputComponent = null
var movement: TopDownMovement = null
var health: HealthComponent = null
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	input_comp = component_host.get_component("InputComponent")
	movement = component_host.get_component("TopDownMovement")
	health = component_host.get_component("HealthComponent")
	
	if not input_comp:
		push_error("InputComponent not found!")
		return
	
	# Setup input actions
	_setup_input_actions()
	
	# Connect to input signals
	input_comp.action_pressed.connect(_on_action_pressed)
	input_comp.action_released.connect(_on_action_released)
	
	print("[Player] Ready with InputComponent!")
	print("Use WASD to move, Space to jump, E to interact")

func _physics_process(_delta: float) -> void:
	if not input_comp or not movement:
		return
	
	_handle_movement()
	_handle_actions()
#endregion

#region Input Setup
func _setup_input_actions() -> void:
	# Movement actions
	input_comp.add_action("move_left", [KEY_A, KEY_LEFT])
	input_comp.add_action("move_right", [KEY_D, KEY_RIGHT])
	input_comp.add_action("move_up", [KEY_W, KEY_UP])
	input_comp.add_action("move_down", [KEY_S, KEY_DOWN])
	
	# Action buttons
	input_comp.add_action("jump", [KEY_SPACE, JOY_BUTTON_A])
	input_comp.add_action("interact", [KEY_E, JOY_BUTTON_B])
	input_comp.add_action("attack", [KEY_J, JOY_BUTTON_X])
	input_comp.add_action("sprint", [KEY_SHIFT, JOY_BUTTON_L])
	
	# UI actions
	input_comp.add_action("pause", [KEY_ESCAPE, JOY_BUTTON_START])
	
	print("[Player] Input actions configured")
#endregion

#region Input Handling
func _handle_movement() -> void:
	# Get movement vector from input component
	var move_vector = input_comp.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)
	
	movement.set_input_direction(move_vector)
	
	# Handle sprint
	if input_comp.is_action_pressed("sprint"):
		movement.start_sprint()
	else:
		movement.stop_sprint()

func _handle_actions() -> void:
	# Jump (just pressed check with buffering)
	if input_comp.is_action_just_pressed("jump"):
		_perform_jump()
	
	# Interact
	if input_comp.is_action_just_pressed("interact"):
		_perform_interact()
	
	# Attack
	if input_comp.is_action_just_pressed("attack"):
		_perform_attack()
	
	# Pause
	if input_comp.is_action_just_pressed("pause"):
		_toggle_pause()
#endregion

#region Actions
func _perform_jump() -> void:
	print("[Player] Jump!")
	# In a real game, this would trigger jump logic
	# For now, just visual feedback
	$Sprite.scale = Vector2(1.2, 0.8)
	await get_tree().create_timer(0.1).timeout
	$Sprite.scale = Vector2.ONE

func _perform_interact() -> void:
	print("[Player] Interact!")
	# Check for nearby interactable objects
	var overlapping = $InteractionArea.get_overlapping_areas()
	if overlapping.size() > 0:
		print("  Found %d interactable objects" % overlapping.size())

func _perform_attack() -> void:
	print("[Player] Attack!")
	# Trigger attack animation/hitbox
	modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE

func _toggle_pause() -> void:
	print("[Player] Pause toggled")
	# In real game, this would pause the game
	get_tree().paused = not get_tree().paused
#endregion

#region Signal Callbacks
func _on_action_pressed(action_name: String) -> void:
	# This is called for ALL action presses
	# Useful for global handling, sound effects, etc.
	pass

func _on_action_released(action_name: String) -> void:
	# Called when actions are released
	pass
#endregion
