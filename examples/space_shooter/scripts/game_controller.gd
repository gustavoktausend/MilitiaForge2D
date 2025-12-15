## Game Controller for Space Shooter
##
## Main game controller that manages the game state, UI, and coordinates
## between player, enemies, and wave manager.

extends Node

#region Signals
signal game_started()
signal game_over()
signal score_changed(new_score: int)
signal health_changed(current_health: int, max_health: int)
#endregion

#region Node References
@onready var player: Node2D = null
@onready var wave_manager: Node2D = null
@onready var hud: Control = null
#endregion

#region Game State
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_score: int = 0
var high_score: int = 0
#endregion

func _ready() -> void:
	# Add to game_controller group so player can find us
	add_to_group("game_controller")

	# Load high score from save file
	_load_high_score()

	# Start game automatically for now
	call_deferred("start_game")

func _process(_delta: float) -> void:
	# Handle pause
	if Input.is_action_just_pressed("ui_cancel") and current_state == GameState.PLAYING:
		toggle_pause()

func start_game() -> void:
	print("[GameController] Starting game...")
	current_state = GameState.PLAYING
	current_score = 0

	game_started.emit()

	# Find or create player
	_setup_player()

	# Find or create wave manager
	_setup_wave_manager()

	# Setup HUD
	_setup_hud()

func _setup_player() -> void:
	# Look for existing player in scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		# Create player
		player = Node2D.new()
		player.set_script(preload("res://examples/space_shooter/scripts/player_controller.gd"))
		player.add_to_group("player")

		# Position at bottom center of play area (between HUD panels)
		var viewport_rect = get_viewport().get_visible_rect()
		player.global_position = Vector2(
			320 + 320,  # Left panel (320px) + half of play area (320px) = center of play area
			viewport_rect.size.y - 100
		)

		get_tree().root.add_child(player)

	# Connect player signals if available
	if player.has_signal("score_changed"):
		player.score_changed.connect(_on_score_changed)

func _setup_wave_manager() -> void:
	# Look for existing wave manager
	var managers = get_tree().get_nodes_in_group("wave_manager")
	if managers.size() > 0:
		wave_manager = managers[0]
	else:
		# Create wave manager
		wave_manager = Node2D.new()
		wave_manager.set_script(preload("res://examples/space_shooter/scripts/wave_manager.gd"))
		wave_manager.add_to_group("wave_manager")
		get_tree().root.add_child(wave_manager)

	# Connect signals
	if wave_manager.has_method("set_game_controller"):
		wave_manager.set_game_controller(self)

	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)
	if wave_manager.has_signal("wave_completed"):
		wave_manager.wave_completed.connect(_on_wave_completed)
	if wave_manager.has_signal("all_waves_completed"):
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)

func _setup_hud() -> void:
	# HUD will be setup when we create the UI
	pass

func add_score(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)

	# Update high score
	if current_score > high_score:
		high_score = current_score
		_save_high_score()

	print("[GameController] Score: %d (High: %d)" % [current_score, high_score])

func end_game() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║        🎮 GAME CONTROLLER - END_GAME CALLED 🎮        ║")
	print("╚═══════════════════════════════════════════════════════╝")

	if current_state == GameState.GAME_OVER:
		print("[GameController] Already in GAME_OVER state, ignoring")
		return

	print("[GameController] 🏁 GAME OVER! Final Score: %d" % current_score)
	print("[GameController] Setting state to GAME_OVER...")
	current_state = GameState.GAME_OVER

	print("[GameController] Emitting game_over signal...")
	game_over.emit()

	print("[GameController] Game Over sequence complete!")

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		print("[GameController] Game Paused")
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		print("[GameController] Game Resumed")

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_wave_started(wave_number: int) -> void:
	print("[GameController] Wave %d started!" % wave_number)

func _on_wave_completed(wave_number: int) -> void:
	print("[GameController] Wave %d completed!" % wave_number)
	# Bonus score for completing wave
	add_score(500 * wave_number)

func _on_all_waves_completed() -> void:
	print("[GameController] All waves completed! You win!")
	# Big bonus for winning
	add_score(5000)
	await get_tree().create_timer(2.0).timeout
	_show_victory_screen()

func _on_score_changed(new_score: int) -> void:
	add_score(new_score)

func _show_game_over_screen() -> void:
	# Game Over UI is now handled by the HUD via game_over signal
	print("[GameController] Game Over screen is handled by HUD")

func _show_victory_screen() -> void:
	print("[GameController] Showing Victory screen...")
	print("You won! Final Score: %d" % current_score)

func _load_high_score() -> void:
	# Simple high score loading (can be enhanced with FileAccess)
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		high_score = file.get_32()
		file.close()
		print("[GameController] Loaded high score: %d" % high_score)

func _save_high_score() -> void:
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_32(high_score)
	file.close()
	print("[GameController] Saved high score: %d" % high_score)

func get_current_score() -> int:
	return current_score

func get_high_score() -> int:
	return high_score
