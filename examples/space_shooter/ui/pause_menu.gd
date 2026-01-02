## Pause Menu - Neon Hotline Miami Style
##
## Full-screen pause overlay with resume, restart, and quit options.
## Matches the game's neon aesthetic.

extends CanvasLayer

#region Signals
signal resume_requested
signal restart_requested
signal quit_to_menu_requested
#endregion

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const DARK_BG: Color = Color(0.05, 0.0, 0.1, 0.85)
#endregion

#region Node References
var overlay: ColorRect
var resume_button: Button
var restart_button: Button
var quit_button: Button
var title_label: Label
#endregion

#region State
var is_paused: bool = false
#endregion

func _ready() -> void:
	# Make sure this layer is on top
	layer = 100

	# Don't process input when not paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_pause_ui()

	# Ensure menu starts hidden
	is_paused = false
	visible = false

	# Make absolutely sure the tree is not paused on start
	if get_tree():
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	# Only process pause input when game is actually running
	# Don't trigger during menus or scene transitions
	if not get_tree():
		return

	# Check if we're in the main game scene (not menu scenes)
	var root = get_tree().root
	if not root:
		return

	# Only allow pause if we have a game controller and it's in PLAYING or PAUSED state
	var controllers = get_tree().get_nodes_in_group("game_controller")
	if controllers.is_empty():
		return

	var game_controller = controllers[0]

	# Check if game_controller has current_state property
	if not "current_state" in game_controller:
		return

	var current_state = game_controller.current_state

	# Only process pause during gameplay (states 1=PLAYING or 2=PAUSED)
	if current_state != 1 and current_state != 2:
		return

	# Toggle pause with ESC or designated pause key
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if is_paused:
			_on_resume_pressed()
		else:
			show_pause_menu()
		get_viewport().set_input_as_handled()

func _create_pause_ui() -> void:
	# Dark overlay background
	overlay = ColorRect.new()
	overlay.color = DARK_BG
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# Center container
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	overlay.add_child(center)

	# Main panel
	var main_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.0, 0.1, 0.95)
	panel_style.set_border_width_all(6)
	panel_style.border_color = NEON_CYAN
	panel_style.set_corner_radius_all(0)
	panel_style.set_expand_margin_all(4)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(main_panel)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 60)
	main_panel.add_child(margin)

	# VBox container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	margin.add_child(vbox)

	# PAUSED title
	title_label = Label.new()
	title_label.text = "◢◤ PAUSED ◥◣"
	title_label.add_theme_font_size_override("font_size", 80)
	title_label.add_theme_color_override("font_color", NEON_CYAN)
	title_label.add_theme_color_override("font_outline_color", NEON_PINK)
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Separator
	var sep1 = _create_separator(NEON_CYAN)
	vbox.add_child(sep1)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "ESC to Resume"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", NEON_PURPLE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Buttons
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_vbox)

	# Resume button
	resume_button = _create_button("▶ RESUME ◀", NEON_GREEN)
	resume_button.pressed.connect(_on_resume_pressed)
	buttons_vbox.add_child(resume_button)

	# Restart button
	restart_button = _create_button("↻ RESTART ↻", NEON_YELLOW)
	restart_button.pressed.connect(_on_restart_pressed)
	buttons_vbox.add_child(restart_button)

	# Separator
	var sep2 = _create_separator(NEON_PINK)
	vbox.add_child(sep2)

	# Quit button
	quit_button = _create_button("◀ QUIT TO MENU ▶", NEON_PINK)
	quit_button.pressed.connect(_on_quit_pressed)
	buttons_vbox.add_child(quit_button)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# Footer tip
	var tip = Label.new()
	tip.text = "◆ TIP: Destroy combos to increase score multiplier ◆"
	tip.add_theme_font_size_override("font_size", 16)
	tip.add_theme_color_override("font_color", NEON_PURPLE)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tip)

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(400, 70)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", Color.BLACK)

	# Normal state
	var normal = StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_border_width_all(4)
	normal.border_color = Color(color, 1.5)
	normal.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("normal", normal)

	# Hover state
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(color, 1.3)
	hover.set_border_width_all(4)
	hover.border_color = Color.WHITE
	hover.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed state
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(color, 0.7)
	pressed.set_border_width_all(4)
	pressed.border_color = color
	pressed.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn

func _create_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

#region Public Methods
func show_pause_menu() -> void:
	if is_paused:
		return

	is_paused = true
	visible = true
	get_tree().paused = true

	# Play UI sound if AudioManager exists
	if AudioManager:
		AudioManager.play_ui_sound("button_click", 0.8)

	# Animate entrance
	_animate_entrance()

	# Focus resume button
	if resume_button:
		resume_button.grab_focus()

func hide_pause_menu() -> void:
	is_paused = false
	visible = false

	if get_tree():
		get_tree().paused = false

	# Play UI sound if AudioManager exists
	if AudioManager:
		AudioManager.play_ui_sound("button_click", 1.0)
#endregion

#region Private Methods
func _animate_entrance() -> void:
	if not overlay:
		return

	# Fade in overlay
	overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.2)

	# Scale punch title
	if title_label:
		title_label.scale = Vector2(0.8, 0.8)
		var title_tween = create_tween().set_parallel(true)
		title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_resume_pressed() -> void:
	hide_pause_menu()
	resume_requested.emit()

func _on_restart_pressed() -> void:
	hide_pause_menu()
	restart_requested.emit()

func _on_quit_pressed() -> void:
	hide_pause_menu()
	quit_to_menu_requested.emit()
#endregion
