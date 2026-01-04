## Neon HUD - Hotline Miami Style
##
## Ultra-stylish HUD with neon colors, chromatic aberration, glitch effects,
## pulsing animations, and screen shake. Maximum visual impact!
##
## REFACTORED: Now uses component-based architecture for better maintainability.

extends CanvasLayer

#region Component Scripts
const ScoreDisplay = preload("res://examples/space_shooter/ui/components/score_display.gd")
const ComboDisplay = preload("res://examples/space_shooter/ui/components/combo_display.gd")
const HealthDisplay = preload("res://examples/space_shooter/ui/components/health_display.gd")
const WaveDisplay = preload("res://examples/space_shooter/ui/components/wave_display.gd")
const CreditDisplay = preload("res://examples/space_shooter/ui/components/credit_display.gd")  # FASE 2
#endregion

#region Constants
const PLAY_AREA_WIDTH: float = 960.0
const SIDE_PANEL_WIDTH: float = 480.0

# NEON COLORS - Hotline Miami palette
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)  # Hot pink
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)  # Bright cyan
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)  # Electric yellow
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)  # Deep purple
const NEON_ORANGE: Color = Color(1.0, 0.41, 0.0)  # Hot orange
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)  # Toxic green
const DARK_BG: Color = Color(0.05, 0.0, 0.1, 0.9)  # Almost black purple
#endregion

#region Component References
var score_display: Node  # ScoreDisplay component
var combo_display: Node  # ComboDisplay component
var health_display: Node  # HealthDisplay component
var wave_display: Node   # WaveDisplay component
var credit_display: Node  # CreditDisplay component - FASE 2
var weapons_hud: WeaponsHUD
#endregion

#region Panel References
var left_panel: Panel
var right_panel: Panel
var screen_flash: ColorRect
var game_over_overlay: ColorRect
var restart_button: Button
var menu_button: Button
#endregion

#region Private Variables
var game_controller: Node = null
var player: Node2D = null
var wave_manager: Node2D = null
var camera: Camera2D = null  # For screen shake
#endregion

func _ready() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║          🎨 NEON HUD INITIALIZING 🎨                  ║")
	print("╚═══════════════════════════════════════════════════════╝")
	_create_screen_flash()
	_create_hud_elements()
	print("[HUD] HUD elements created, connecting to game...")
	call_deferred("_connect_to_game")
	print("[HUD] HUD initialization complete!")

func _create_screen_flash() -> void:
	# Full-screen flash overlay for damage/kill effects
	screen_flash = ColorRect.new()
	screen_flash.color = Color(1, 0, 0, 0)  # Transparent red
	screen_flash.anchor_right = 1.0
	screen_flash.anchor_bottom = 1.0
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.z_index = 100
	add_child(screen_flash)

func _create_hud_elements() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	# LEFT PANEL - Neon cyberpunk style
	left_panel = Panel.new()
	left_panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, viewport_size.y)
	left_panel.position = Vector2(0, 0)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DARK_BG
	panel_style.set_border_width_all(4)
	panel_style.border_color = NEON_CYAN
	panel_style.set_expand_margin_all(2)  # Glow effect
	left_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(left_panel)

	# RIGHT PANEL - Mirror style (for weapons)
	right_panel = Panel.new()
	right_panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, viewport_size.y)
	right_panel.position = Vector2(viewport_size.x - SIDE_PANEL_WIDTH, 0)
	var right_style = panel_style.duplicate()
	right_style.border_color = NEON_PINK
	right_panel.add_theme_stylebox_override("panel", right_style)
	add_child(right_panel)

	# RIGHT PANEL CONTENT - Weapons HUD
	_create_right_panel_content()

	# LEFT PANEL CONTENT - Using components
	_create_left_panel_content()

	# COMBO DISPLAY - Positioned in play area
	_create_combo_display(viewport_size)

	# GAME OVER OVERLAY
	_create_game_over_overlay(viewport_size)

func _create_left_panel_content() -> void:
	var left_margin = MarginContainer.new()
	left_margin.anchor_right = 1.0
	left_margin.anchor_bottom = 1.0
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_top", 40)
	left_margin.add_theme_constant_override("margin_right", 30)
	left_margin.add_theme_constant_override("margin_bottom", 40)
	left_panel.add_child(left_margin)

	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 40)
	left_margin.add_child(info_vbox)

	# TITLE - Glitchy neon
	var title = Label.new()
	title.text = "◢ SPACE SHOOTER ◣"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", NEON_CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(title)
	_add_glow_effect(title, NEON_CYAN)

	# Neon separator
	var sep1 = _create_neon_separator(NEON_CYAN)
	info_vbox.add_child(sep1)

	# SCORE COMPONENT
	score_display = ScoreDisplay.new()
	info_vbox.add_child(score_display)

	# WAVE COMPONENT
	wave_display = WaveDisplay.new()
	info_vbox.add_child(wave_display)

	# CREDIT COMPONENT - FASE 2
	credit_display = CreditDisplay.new()
	info_vbox.add_child(credit_display)

	# HEALTH COMPONENT
	health_display = HealthDisplay.new()
	health_display.damage_flash_requested.connect(_on_damage_flash_requested)
	health_display.shake_requested.connect(_on_shake_requested)
	info_vbox.add_child(health_display)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)

func _create_combo_display(viewport_size: Vector2) -> void:
	combo_display = ComboDisplay.new()
	combo_display.anchor_left = SIDE_PANEL_WIDTH / viewport_size.x
	combo_display.anchor_right = (viewport_size.x - SIDE_PANEL_WIDTH) / viewport_size.x
	combo_display.anchor_top = 0.2
	combo_display.anchor_bottom = 0.3
	combo_display.combo_flash_requested.connect(_on_combo_flash_requested)
	add_child(combo_display)

func _create_right_panel_content() -> void:
	var right_margin = MarginContainer.new()
	right_margin.anchor_right = 1.0
	right_margin.anchor_bottom = 1.0
	right_margin.add_theme_constant_override("margin_left", 20)
	right_margin.add_theme_constant_override("margin_top", 40)
	right_margin.add_theme_constant_override("margin_right", 20)
	right_margin.add_theme_constant_override("margin_bottom", 40)
	right_panel.add_child(right_margin)

	weapons_hud = WeaponsHUD.new()
	weapons_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(weapons_hud)

	print("[HUD] Weapons HUD created in RIGHT PANEL")

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

func _add_glow_effect(label: Label, glow_color: Color) -> void:
	label.add_theme_color_override("font_outline_color", glow_color)
	label.add_theme_constant_override("outline_size", 4)

func _create_game_over_overlay(viewport_size: Vector2) -> void:
	# ULTRA NEON GAME OVER
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.05, 0.0, 0.1, 0.95)  # Dark purple
	game_over_overlay.anchor_right = 1.0
	game_over_overlay.anchor_bottom = 1.0
	game_over_overlay.visible = false
	add_child(game_over_overlay)

	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	game_over_overlay.add_child(center)

	var main_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DARK_BG
	panel_style.set_border_width_all(6)
	panel_style.border_color = NEON_PINK
	panel_style.set_corner_radius_all(0)  # Sharp edges = retro
	panel_style.set_expand_margin_all(4)  # Glow
	main_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(main_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 60)
	main_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 35)
	margin.add_child(vbox)

	# GAME OVER title - HUGE AND PINK
	var title = Label.new()
	title.text = "◢◤ GAME OVER ◥◣"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", NEON_PINK)
	title.add_theme_color_override("font_outline_color", NEON_CYAN)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep1 = _create_neon_separator(NEON_CYAN)
	vbox.add_child(sep1)

	# Stats
	var stats = VBoxContainer.new()
	stats.add_theme_constant_override("separation", 20)
	vbox.add_child(stats)

	var final_score = Label.new()
	final_score.name = "FinalScoreLabel"
	final_score.text = "FINAL SCORE: 0"
	final_score.add_theme_font_size_override("font_size", 48)
	final_score.add_theme_color_override("font_color", NEON_YELLOW)
	final_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(final_score)

	var high_score = Label.new()
	high_score.name = "GameOverHighScore"
	high_score.text = "HIGH SCORE: 0"
	high_score.add_theme_font_size_override("font_size", 28)
	high_score.add_theme_color_override("font_color", NEON_CYAN)
	high_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(high_score)

	var wave_reached = Label.new()
	wave_reached.name = "WaveReachedLabel"
	wave_reached.text = "WAVE REACHED: 1"
	wave_reached.add_theme_font_size_override("font_size", 24)
	wave_reached.add_theme_color_override("font_color", NEON_PURPLE)
	wave_reached.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(wave_reached)

	var sep2 = _create_neon_separator(NEON_PINK)
	vbox.add_child(sep2)

	# BUTTONS - Neon style
	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 30)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons)

	restart_button = _create_neon_button("▶ RESTART ◀", NEON_GREEN)
	restart_button.pressed.connect(_on_restart_pressed)
	buttons.add_child(restart_button)

	menu_button = _create_neon_button("◀ MENU ▶", NEON_PINK)
	menu_button.pressed.connect(_on_menu_pressed)
	buttons.add_child(menu_button)

func _create_neon_button(text: String, neon_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 70)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.BLACK)

	var normal = StyleBoxFlat.new()
	normal.bg_color = neon_color
	normal.set_border_width_all(4)
	normal.border_color = Color(neon_color, 1.5)
	normal.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(neon_color, 1.3)
	hover.set_border_width_all(4)
	hover.border_color = Color.WHITE
	hover.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(neon_color, 0.7)
	pressed.set_border_width_all(4)
	pressed.border_color = neon_color
	pressed.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn

func _connect_to_game() -> void:
	var controllers = get_tree().get_nodes_in_group("game_controller")
	print("[HUD] Looking for game_controller... found %d" % controllers.size())
	if controllers.size() > 0:
		game_controller = controllers[0]
		print("[HUD] Connected to game_controller!")
		if game_controller.has_signal("score_changed"):
			game_controller.score_changed.connect(_on_score_changed)
			print("[HUD] Connected to score_changed signal")
		if game_controller.has_signal("credits_changed"):
			game_controller.credits_changed.connect(_on_credits_changed)
			print("[HUD] Connected to credits_changed signal (FASE 2)")
		if game_controller.has_signal("game_over"):
			game_controller.game_over.connect(_on_game_over)
			print("[HUD] Connected to game_over signal")
	else:
		push_warning("[HUD] No game_controller found in scene!")

	var players = get_tree().get_nodes_in_group("player")
	print("[HUD] Looking for player... found %d" % players.size())
	if players.size() > 0:
		player = players[0]
		print("[HUD] Found player! Waiting for player_ready signal...")
		if player.has_signal("player_ready"):
			player.player_ready.connect(_on_player_ready)
			print("[HUD] ✅ Connected to player_ready signal - will connect to components when player is initialized")
		else:
			push_warning("[HUD] Player doesn't have player_ready signal, falling back to direct connection")
			_connect_to_player()
	else:
		print("[HUD] WARNING: No player found in scene!")

	var managers = get_tree().get_nodes_in_group("wave_manager")
	if managers.size() > 0:
		wave_manager = managers[0]
		_connect_to_wave_manager()

	# Find camera for screen shake
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		camera = cameras[0]

	_update_display()

func _on_player_ready(player_node: Node2D) -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║         🎯 HUD: PLAYER READY SIGNAL RECEIVED 🎯       ║")
	print("╚═══════════════════════════════════════════════════════╝")
	player = player_node
	_connect_to_player()

func _connect_to_player() -> void:
	print("[HUD] _connect_to_player called - Player is ready!")
	if not player:
		push_error("[HUD] ERROR: player is null!")
		return

	if not player.has_node("PlayerHost"):
		push_error("[HUD] ❌ PlayerHost not found on player!")
		return

	var host = player.get_node("PlayerHost")
	var health = host.get_component("HealthComponent")

	if health:
		print("[HUD] ✅ Found HealthComponent! Current health: %d/%d" % [health.current_health, health.max_health])
		health.health_changed.connect(_on_health_changed)
		print("[HUD] ✅ Connected to health_changed signal")
		health.damage_taken.connect(_on_damage_taken)
		print("[HUD] ✅ Connected to damage_taken signal")

		# Initialize health display
		if health_display:
			health_display.initialize_health(health.max_health)
			health_display.set_health(health.current_health, health.max_health)
	else:
		push_error("[HUD] ❌ HealthComponent not found on PlayerHost!")

	var score_comp = host.get_component("ScoreComponent")
	if score_comp:
		score_comp.score_changed.connect(_on_player_score_changed)
		score_comp.combo_changed.connect(_on_combo_changed)
		print("[HUD] ✅ Connected to ScoreComponent")
	else:
		print("[HUD] ⚠️ ScoreComponent not found (this is optional)")

	# Connect WeaponsHUD to player
	if weapons_hud:
		weapons_hud.set_player(player)
		print("[HUD] ✅ Connected WeaponsHUD to player")

func _connect_to_wave_manager() -> void:
	if not wave_manager:
		return
	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)

#region Signal Handlers - Delegating to Components
func _on_score_changed(new_score: int) -> void:
	print("[HUD] _on_score_changed called! New score: %d" % new_score)
	if score_display:
		score_display.set_score(new_score)

	if game_controller and score_display:
		score_display.set_high_score(game_controller.get_high_score())

func _on_credits_changed(new_credits: int, delta: int) -> void:
	print("[HUD] _on_credits_changed called! Credits: %d (Δ%+d)" % [new_credits, delta])
	if credit_display:
		credit_display.set_credits(new_credits, delta)

func _on_player_score_changed(new_score: int, _old: int) -> void:
	if game_controller:
		game_controller.add_score(new_score)

func _on_health_changed(new_health: int, _old_health: int) -> void:
	print("[HUD] _on_health_changed called! New: %d" % new_health)
	if health_display and player:
		var host = player.get_node("PlayerHost")
		var health = host.get_component("HealthComponent")
		if health:
			health_display.set_health(new_health, health.max_health)

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	if health_display:
		health_display.on_damage_taken(amount)

func _on_wave_started(wave_number: int) -> void:
	if wave_manager and wave_display:
		var total = wave_manager.get_total_waves()
		wave_display.set_wave(wave_number, total)

func _on_combo_changed(combo: int, multiplier: float) -> void:
	if combo_display:
		combo_display.show_combo(combo, multiplier)

func _update_display() -> void:
	print("[HUD] _update_display called")
	if game_controller and score_display:
		var current = game_controller.get_current_score()
		print("[HUD] Initial score from game_controller: %d" % current)
		_on_score_changed(current)
	else:
		print("[HUD] WARNING: game_controller or score_display is null!")
#endregion

#region Component Signal Handlers (Screen Effects)
func _on_damage_flash_requested(color: Color, duration: float) -> void:
	_flash_screen(color, duration)

func _on_shake_requested(intensity: float, duration: float) -> void:
	_screen_shake(intensity, duration)

func _on_combo_flash_requested(color: Color, duration: float) -> void:
	_flash_screen(color, duration)

func _flash_screen(color: Color, duration: float) -> void:
	if screen_flash:
		screen_flash.color = color
		var tween = create_tween()
		tween.tween_property(screen_flash, "color:a", 0.0, duration)

func _screen_shake(intensity: float, duration: float) -> void:
	if not camera:
		return

	var original_offset = camera.offset
	var tween = create_tween()

	for i in range(int(duration / 0.05)):
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original_offset + shake_offset, 0.05)

	tween.tween_property(camera, "offset", original_offset, 0.05)
#endregion

#region Game Over
func _on_game_over() -> void:
	print("[NeonHUD] Game Over!")

	# Update stats
	if game_controller:
		var final = game_controller.get_current_score()
		var high = game_controller.get_high_score()

		var final_label = game_over_overlay.find_child("FinalScoreLabel", true, false)
		if final_label:
			final_label.text = "FINAL SCORE: %d" % final

		var high_label = game_over_overlay.find_child("GameOverHighScore", true, false)
		if high_label:
			if final >= high:
				high_label.text = "◆◆◆ NEW HIGH SCORE ◆◆◆"
				high_label.add_theme_color_override("font_color", NEON_YELLOW)
			else:
				high_label.text = "HIGH SCORE: %d" % high

	if wave_manager:
		var wave_label_go = game_over_overlay.find_child("WaveReachedLabel", true, false)
		if wave_label_go:
			wave_label_go.text = "WAVE REACHED: %d" % wave_manager.current_wave

	# Dramatic entrance
	game_over_overlay.modulate.a = 0.0
	game_over_overlay.visible = true

	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate:a", 1.0, 0.8)

	# Screen shake on game over
	_screen_shake(15.0, 1.0)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://examples/space_shooter/scenes/main_menu.tscn")
#endregion

#region Static Helpers
static func get_play_area() -> Rect2:
	var viewport_size = DisplayServer.window_get_size()
	return Rect2(
		Vector2(SIDE_PANEL_WIDTH, 0),
		Vector2(viewport_size.x - SIDE_PANEL_WIDTH * 2, viewport_size.y)
	)
#endregion
