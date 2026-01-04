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
signal credits_changed(new_credits: int, delta: int)  # FASE 2: Credit system
#endregion

#region Node References
@onready var player: Node2D = null
@onready var wave_manager: Node2D = null
@onready var hud: Control = null
@onready var pause_menu: CanvasLayer = null
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

# FASE 2: Credit System (currency for shop)
var current_credits: int = 0
#endregion

func _ready() -> void:
	# Add to game_controller group so player can find us
	add_to_group("game_controller")

	# Load high score from save file
	_load_high_score()

	# Setup pause menu
	_setup_pause_menu()

	# Start game automatically for now
	call_deferred("start_game")

func start_game() -> void:
	print("[GameController] Starting game...")
	current_state = GameState.PLAYING
	current_score = 0
	current_credits = 0  # FASE 2: Reset credits on game start

	# FASE 3: Initialize shop database and reset upgrades
	ShopDatabase.initialize()
	if UpgradeManager:
		UpgradeManager.reset_all_upgrades()

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

	# Connect signals using Observer Pattern
	# WaveManager emits events, GameController listens and reacts
	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)
	if wave_manager.has_signal("wave_completed"):
		wave_manager.wave_completed.connect(_on_wave_completed)
	if wave_manager.has_signal("all_waves_completed"):
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	if wave_manager.has_signal("enemy_killed"):
		wave_manager.enemy_killed.connect(_on_enemy_killed)
		print("[GameController] ✅ Connected to WaveManager.enemy_killed signal")

func _setup_hud() -> void:
	# HUD will be setup when we create the UI
	pass

func _setup_pause_menu() -> void:
	# Create pause menu
	var PauseMenu = load("res://examples/space_shooter/ui/pause_menu.gd")
	pause_menu = CanvasLayer.new()
	pause_menu.set_script(PauseMenu)
	pause_menu.name = "PauseMenu"
	get_tree().root.add_child(pause_menu)

	# Connect signals
	if pause_menu.has_signal("resume_requested"):
		pause_menu.resume_requested.connect(_on_pause_resume)
	if pause_menu.has_signal("restart_requested"):
		pause_menu.restart_requested.connect(_on_pause_restart)
	if pause_menu.has_signal("quit_to_menu_requested"):
		pause_menu.quit_to_menu_requested.connect(_on_pause_quit)

	print("[GameController] ✅ Pause menu created and connected")

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
		if pause_menu:
			pause_menu.show_pause_menu()
		else:
			get_tree().paused = true
		print("[GameController] Game Paused")
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		if pause_menu:
			pause_menu.hide_pause_menu()
		else:
			get_tree().paused = false
		print("[GameController] Game Resumed")

func restart_game() -> void:
	get_tree().paused = false
	# Simple reload (transition system available for future use)
	get_tree().reload_current_scene()

func _on_wave_started(wave_number: int) -> void:
	print("[GameController] Wave %d started!" % wave_number)

func _on_wave_completed(wave_number: int) -> void:
	print("[GameController] Wave %d completed!" % wave_number)
	# Bonus score for completing wave
	add_score(500 * wave_number)
	# FASE 2: Credit bonus for completing wave
	add_credits(50 * wave_number)

func _on_all_waves_completed() -> void:
	print("[GameController] All waves completed! You win!")
	# Big bonus for winning
	add_score(5000)
	await get_tree().create_timer(2.0).timeout
	_show_victory_screen()

func _on_enemy_killed(score_value: int) -> void:
	# Observer Pattern: React to enemy death by adding score
	# WaveManager doesn't know about GameController, just emits the event
	print("[GameController] Enemy killed! Adding %d points to score" % score_value)
	add_score(score_value)

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

#region FASE 2: Credit System
## Add credits to player's wallet
func add_credits(amount: int) -> void:
	if amount <= 0:
		return

	current_credits += amount
	credits_changed.emit(current_credits, amount)
	print("[GameController] +%d credits → Total: %d 💎" % [amount, current_credits])

## Spend credits (returns true if successful)
func spend_credits(amount: int) -> bool:
	if amount <= 0:
		push_warning("[GameController] Cannot spend negative or zero credits")
		return false

	if current_credits < amount:
		print("[GameController] ❌ Not enough credits! Need %d, have %d" % [amount, current_credits])
		return false

	current_credits -= amount
	credits_changed.emit(current_credits, -amount)
	print("[GameController] -%d credits → Remaining: %d 💎" % [amount, current_credits])
	return true

## Check if player can afford an item
func can_afford(amount: int) -> bool:
	return current_credits >= amount

## Get current credits
func get_credits() -> int:
	return current_credits
#endregion

#region Pause Menu Signal Handlers
func _on_pause_resume() -> void:
	print("[GameController] Resume requested from pause menu")
	current_state = GameState.PLAYING

func _on_pause_restart() -> void:
	print("[GameController] Restart requested from pause menu")
	restart_game()

func _on_pause_quit() -> void:
	print("[GameController] Quit to menu requested from pause menu")
	get_tree().paused = false
	# Use SceneManager to transition to main menu with effect
	var fade_out_options = SceneManager.create_options(0.5, "squares")
	var fade_in_options = SceneManager.create_options(0.3, "squares")
	var general_options = SceneManager.create_general_options()
	SceneManager.change_scene("main_menu", fade_out_options, fade_in_options, general_options)
#endregion
