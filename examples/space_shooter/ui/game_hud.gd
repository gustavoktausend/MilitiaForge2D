## Neon HUD - Hotline Miami Style
##
## Ultra-stylish HUD with neon colors, chromatic aberration, glitch effects,
## pulsing animations, and screen shake. Maximum visual impact!

extends CanvasLayer

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

#region Node References
var health_bar: ProgressBar
var health_value_label: Label
var score_label: Label
var score_shadow: Label  # Chromatic aberration effect
var wave_label: Label
var combo_label: Label
var high_score_label: Label
var left_panel: Panel
var right_panel: Panel
var game_over_overlay: ColorRect
var restart_button: Button
var menu_button: Button
var screen_flash: ColorRect  # For damage/kill flash effects
#endregion

#region Animation Variables
var score_pulse_tween: Tween
var health_shake_tween: Tween
var combo_scale_tween: Tween
var current_score: int = 0
var target_score: int = 0
var score_animation_speed: float = 500.0  # Points per second (fast for arcade feel)
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
	_start_background_animations()
	print("[HUD] HUD initialization complete!")

func _process(delta: float) -> void:
	# Smooth score counter animation
	if current_score < target_score:
		current_score += int(score_animation_speed * delta)
		if current_score > target_score:
			current_score = target_score
		_update_score_display()

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

	# RIGHT PANEL - Mirror style
	right_panel = Panel.new()
	right_panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, viewport_size.y)
	right_panel.position = Vector2(viewport_size.x - SIDE_PANEL_WIDTH, 0)
	var right_style = panel_style.duplicate()
	right_style.border_color = NEON_PINK
	right_panel.add_theme_stylebox_override("panel", right_style)
	add_child(right_panel)

	# LEFT PANEL CONTENT
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

	# SCORE SECTION - With chromatic aberration
	var score_container = Control.new()
	score_container.custom_minimum_size = Vector2(0, 150)
	info_vbox.add_child(score_container)

	var score_title = Label.new()
	score_title.text = "▼ SCORE ▼"
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", NEON_YELLOW)
	score_title.position = Vector2(0, 0)
	score_container.add_child(score_title)

	# Score shadow (chromatic aberration - red offset)
	score_shadow = Label.new()
	score_shadow.text = "0"
	score_shadow.add_theme_font_size_override("font_size", 56)
	score_shadow.add_theme_color_override("font_color", Color(NEON_PINK.r, 0, 0, 0.5))
	score_shadow.position = Vector2(-3, 43)  # Slight offset
	score_container.add_child(score_shadow)

	# Main score label (cyan on top)
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.add_theme_color_override("font_color", NEON_CYAN)
	score_label.position = Vector2(0, 40)
	score_container.add_child(score_label)

	high_score_label = Label.new()
	high_score_label.text = "◆ HI: 0"
	high_score_label.add_theme_font_size_override("font_size", 18)
	high_score_label.add_theme_color_override("font_color", NEON_PURPLE)
	high_score_label.position = Vector2(0, 110)
	score_container.add_child(high_score_label)

	var sep2 = _create_neon_separator(NEON_YELLOW)
	info_vbox.add_child(sep2)

	# WAVE SECTION
	var wave_container = VBoxContainer.new()
	wave_container.add_theme_constant_override("separation", 10)
	info_vbox.add_child(wave_container)

	var wave_title = Label.new()
	wave_title.text = "▼ WAVE ▼"
	wave_title.add_theme_font_size_override("font_size", 22)
	wave_title.add_theme_color_override("font_color", NEON_YELLOW)
	wave_container.add_child(wave_title)

	wave_label = Label.new()
	wave_label.text = "1 / 5"
	wave_label.add_theme_font_size_override("font_size", 38)
	wave_label.add_theme_color_override("font_color", NEON_PINK)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_container.add_child(wave_label)
	_add_glow_effect(wave_label, NEON_PINK)

	var sep3 = _create_neon_separator(NEON_PINK)
	info_vbox.add_child(sep3)

	# HEALTH SECTION - Neon bar with glow
	var health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 15)
	info_vbox.add_child(health_container)

	var health_title = Label.new()
	health_title.text = "▼ HULL INTEGRITY ▼"
	health_title.add_theme_font_size_override("font_size", 20)
	health_title.add_theme_color_override("font_color", NEON_GREEN)
	health_container.add_child(health_title)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(0, 40)
	health_bar.show_percentage = false

	# Neon green fill with glow
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = NEON_GREEN
	fill_style.set_border_width_all(3)
	fill_style.border_color = Color(NEON_GREEN, 2.0)  # Bright border
	fill_style.set_expand_margin_all(3)  # Glow effect
	health_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.0, 0.05)
	bg_style.set_border_width_all(3)
	bg_style.border_color = NEON_PINK
	health_bar.add_theme_stylebox_override("background", bg_style)

	health_container.add_child(health_bar)

	# Health value label (centered on bar)
	health_value_label = Label.new()
	health_value_label.text = "100"
	health_value_label.add_theme_font_size_override("font_size", 24)
	health_value_label.add_theme_color_override("font_color", Color.BLACK)
	health_value_label.add_theme_color_override("font_outline_color", NEON_GREEN)
	health_value_label.add_theme_constant_override("outline_size", 8)
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_container.add_child(health_value_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)

	# COMBO LABEL - Massive neon text in play area
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 72)
	combo_label.add_theme_color_override("font_color", NEON_YELLOW)
	combo_label.add_theme_color_override("font_outline_color", NEON_PINK)
	combo_label.add_theme_constant_override("outline_size", 6)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.anchor_left = SIDE_PANEL_WIDTH / viewport_size.x
	combo_label.anchor_right = (viewport_size.x - SIDE_PANEL_WIDTH) / viewport_size.x
	combo_label.anchor_top = 0.2
	combo_label.anchor_bottom = 0.3
	combo_label.visible = false
	combo_label.z_index = 50
	add_child(combo_label)

	_create_game_over_overlay(viewport_size)

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

func _add_glow_effect(label: Label, glow_color: Color) -> void:
	# Outline effect simulates glow
	label.add_theme_color_override("font_outline_color", glow_color)
	label.add_theme_constant_override("outline_size", 4)

func _start_background_animations() -> void:
	# Pulsate title
	var title_labels = get_tree().get_nodes_in_group("hud_title")
	# Pulse wave label
	if wave_label:
		_create_pulse_animation(wave_label)

	# Pulse health bar border when low
	if health_bar:
		_create_health_pulse()

func _create_pulse_animation(node: Control) -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(node, "modulate:a", 0.6, 1.0)
	tween.tween_property(node, "modulate:a", 1.0, 1.0)

func _create_health_pulse() -> void:
	# Will activate when health is low (see _on_health_changed)
	pass

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

	# Player is fully initialized, components should exist now
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

		# Initialize health bar with current value
		_on_health_changed(health.current_health, health.current_health)
	else:
		push_error("[HUD] ❌ HealthComponent not found on PlayerHost!")

	var score_comp = host.get_component("ScoreComponent")
	if score_comp:
		score_comp.score_changed.connect(_on_player_score_changed)
		score_comp.combo_changed.connect(_on_combo_changed)
		print("[HUD] ✅ Connected to ScoreComponent")
	else:
		print("[HUD] ⚠️ ScoreComponent not found (this is optional)")

func _connect_to_wave_manager() -> void:
	if not wave_manager:
		return
	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)

func _on_score_changed(new_score: int) -> void:
	print("[HUD] _on_score_changed called! New score: %d" % new_score)
	target_score = new_score
	_pulse_score()

	if game_controller:
		high_score_label.text = "◆ HI: %d" % game_controller.get_high_score()

func _update_score_display() -> void:
	if score_label:
		score_label.text = "%d" % current_score
	else:
		print("[HUD] WARNING: score_label is null!")
	if score_shadow:
		score_shadow.text = "%d" % current_score
	else:
		print("[HUD] WARNING: score_shadow is null!")

func _pulse_score() -> void:
	if score_pulse_tween:
		score_pulse_tween.kill()

	score_pulse_tween = create_tween()
	score_pulse_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	score_pulse_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_player_score_changed(new_score: int, _old: int) -> void:
	if game_controller:
		game_controller.add_score(new_score)

func _on_health_changed(new_health: int, old_health: int) -> void:
	print("[HUD] _on_health_changed called! New: %d, Old: %d" % [new_health, old_health])
	if health_bar:
		print("[HUD] Updating health bar to %d (max: %d)" % [new_health, health_bar.max_value])
		# Smooth animation
		var tween = create_tween()
		tween.tween_property(health_bar, "value", new_health, 0.3)

		# Update text
		health_value_label.text = "%d" % new_health
	else:
		print("[HUD] WARNING: health_bar is null!")

		# Color shift based on health
		var fill: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
		if new_health < 25:
			fill.bg_color = NEON_PINK
			fill.border_color = Color(NEON_PINK, 2.0)
			health_value_label.add_theme_color_override("font_outline_color", NEON_PINK)
			# Critical health pulse
			_start_critical_health_pulse()
		elif new_health < 50:
			fill.bg_color = NEON_ORANGE
			fill.border_color = Color(NEON_ORANGE, 2.0)
			health_value_label.add_theme_color_override("font_outline_color", NEON_ORANGE)
		else:
			fill.bg_color = NEON_GREEN
			fill.border_color = Color(NEON_GREEN, 2.0)
			health_value_label.add_theme_color_override("font_outline_color", NEON_GREEN)

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	# Red screen flash
	_flash_screen(Color(NEON_PINK.r, 0, 0, 0.3), 0.15)
	# Shake health bar
	_shake_health_bar()
	# Screen shake
	_screen_shake(5.0, 0.2)

func _start_critical_health_pulse() -> void:
	if health_shake_tween:
		health_shake_tween.kill()

	health_shake_tween = create_tween().set_loops()
	health_shake_tween.tween_property(health_bar, "modulate", Color(NEON_PINK, 1.5), 0.3)
	health_shake_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.3)

func _shake_health_bar() -> void:
	var original_pos = health_bar.position
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(health_bar, "position", original_pos + Vector2(randf_range(-3, 3), 0), 0.05)
	tween.tween_property(health_bar, "position", original_pos, 0.05)

func _flash_screen(color: Color, duration: float) -> void:
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

func _on_wave_started(wave_number: int) -> void:
	if wave_manager:
		var total = wave_manager.get_total_waves()
		wave_label.text = "%d / %d" % [wave_number, total]

		# Pulse animation on wave change
		var tween = create_tween()
		tween.tween_property(wave_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(wave_label, "scale", Vector2(1.0, 1.0), 0.2)

func _on_combo_changed(combo: int, multiplier: float) -> void:
	if combo > 1:
		combo_label.text = "◢ COMBO x%d ◣" % combo
		combo_label.visible = true

		# Scale punch animation
		if combo_scale_tween:
			combo_scale_tween.kill()

		combo_scale_tween = create_tween()
		combo_scale_tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.1)
		combo_scale_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)

		# Fade out
		var fade_tween = create_tween()
		fade_tween.tween_property(combo_label, "modulate:a", 0.0, 0.8).set_delay(1.2)
		fade_tween.tween_callback(func(): combo_label.visible = false)
		fade_tween.tween_property(combo_label, "modulate:a", 1.0, 0.0)

		# Screen flash yellow
		_flash_screen(Color(NEON_YELLOW.r, NEON_YELLOW.g, 0, 0.2), 0.2)
	else:
		combo_label.visible = false

func _update_display() -> void:
	print("[HUD] _update_display called")
	if game_controller:
		var current = game_controller.get_current_score()
		print("[HUD] Initial score from game_controller: %d" % current)
		_on_score_changed(current)
	else:
		print("[HUD] WARNING: game_controller is null in _update_display!")

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

static func get_play_area() -> Rect2:
	var viewport_size = DisplayServer.window_get_size()
	return Rect2(
		Vector2(SIDE_PANEL_WIDTH, 0),
		Vector2(viewport_size.x - SIDE_PANEL_WIDTH * 2, viewport_size.y)
	)
