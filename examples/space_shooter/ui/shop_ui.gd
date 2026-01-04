## Shop UI Controller
##
## Main shop interface that opens between waves.
## Handles item display, purchases, and tab switching.

extends CanvasLayer

#region Constants
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)

const ShopItemCard = preload("res://examples/space_shooter/ui/shop_item_card.gd")
#endregion

#region Signals
signal shop_closed
#endregion

#region Node References
var overlay_panel: Panel
var title_label: Label
var credits_label: Label
var tab_container: HBoxContainer
var item_grid: GridContainer
var ready_button: Button
var wave_label: Label
#endregion

#region State
var current_category: ShopItem.Category = ShopItem.Category.TIER1
var current_wave: int = 1
var player_credits: int = 0
var item_cards: Array[Node] = []  # Array of ShopItemCard instances
#endregion

func _ready() -> void:
	layer = 100  # Above everything
	process_mode = Node.PROCESS_MODE_ALWAYS  # Important: Continue processing when paused
	_create_ui()
	hide()
	print("[ShopUI] Ready! Process mode set to ALWAYS")

func _create_ui() -> void:
	# Semi-transparent dark overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.custom_minimum_size = Vector2(1920, 1080)
	add_child(bg)

	# Main shop panel
	overlay_panel = Panel.new()
	overlay_panel.custom_minimum_size = Vector2(1200, 800)
	overlay_panel.position = Vector2(360, 140)  # Center-ish
	add_child(overlay_panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = NEON_CYAN
	overlay_panel.add_theme_stylebox_override("panel", style)

	# Main VBox layout
	var main_vbox = VBoxContainer.new()
	main_vbox.position = Vector2(20, 20)
	main_vbox.custom_minimum_size = Vector2(1160, 760)
	main_vbox.add_theme_constant_override("separation", 15)
	overlay_panel.add_child(main_vbox)

	# Header
	_create_header(main_vbox)

	# Tab buttons
	_create_tabs(main_vbox)

	# Item grid
	_create_item_grid(main_vbox)

	# Footer with Ready button
	_create_footer(main_vbox)

func _create_header(parent: VBoxContainer) -> void:
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	parent.add_child(header_hbox)

	# Title
	title_label = Label.new()
	title_label.text = "🏪 WAVE SHOP 🏪"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", NEON_CYAN)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_label)

	# Wave number
	wave_label = Label.new()
	wave_label.text = "WAVE 1"
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.add_theme_color_override("font_color", NEON_YELLOW)
	header_hbox.add_child(wave_label)

	# Credits display
	credits_label = Label.new()
	credits_label.text = "💎 0"
	credits_label.add_theme_font_size_override("font_size", 40)
	credits_label.add_theme_color_override("font_color", NEON_YELLOW)
	header_hbox.add_child(credits_label)

func _create_tabs(parent: VBoxContainer) -> void:
	tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 10)
	parent.add_child(tab_container)

	# Tab buttons
	_create_tab_button("⚡ TIER 1", ShopItem.Category.TIER1)
	_create_tab_button("💎 TIER 2", ShopItem.Category.TIER2)
	_create_tab_button("⭐ TIER 3", ShopItem.Category.TIER3)
	_create_tab_button("🔥 BUFFS", ShopItem.Category.CONSUMABLE)

func _create_tab_button(text: String, category: ShopItem.Category) -> void:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 50)
	button.add_theme_font_size_override("font_size", 20)
	button.toggle_mode = true
	button.button_pressed = (category == current_category)
	button.pressed.connect(func(): _on_tab_pressed(category, button))
	tab_container.add_child(button)

	# Style active tab
	if category == current_category:
		button.add_theme_color_override("font_color", NEON_CYAN)

func _create_item_grid(parent: VBoxContainer) -> void:
	# Scroll container for items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 500)
	parent.add_child(scroll)

	# Grid container (3 columns)
	item_grid = GridContainer.new()
	item_grid.columns = 3
	item_grid.add_theme_constant_override("h_separation", 15)
	item_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(item_grid)

func _create_footer(parent: VBoxContainer) -> void:
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	parent.add_child(footer)

	# Info label
	var info_label = Label.new()
	info_label.text = "💡 TIP: Upgrades persist until game over"
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", NEON_PURPLE)
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(info_label)

	# Ready button
	ready_button = Button.new()
	ready_button.text = "▶ READY FOR NEXT WAVE ▶"
	ready_button.custom_minimum_size = Vector2(400, 60)
	ready_button.add_theme_font_size_override("font_size", 24)
	ready_button.add_theme_color_override("font_color", NEON_GREEN)
	ready_button.pressed.connect(_on_ready_pressed)
	ready_button.focus_mode = Control.FOCUS_NONE  # Prevent focus issues
	footer.add_child(ready_button)
	print("[ShopUI] Ready button created and connected")

#region Public Methods
func open_shop(wave_number: int) -> void:
	"""Open shop between waves"""
	current_wave = wave_number
	wave_label.text = "WAVE %d" % wave_number

	# Get player credits from GameController
	var game_controller = get_tree().get_first_node_in_group("game_controller")
	if game_controller:
		player_credits = game_controller.get_credits()
	else:
		player_credits = 0

	_update_credits_display()
	_populate_items()

	show()
	get_tree().paused = true

	print("[ShopUI] Shop opened - Wave %d, Credits: %d" % [wave_number, player_credits])

func close_shop() -> void:
	"""Close shop and resume game"""
	hide()
	get_tree().paused = false
	shop_closed.emit()
	print("[ShopUI] Shop closed")
#endregion

#region Private Methods
func _populate_items() -> void:
	"""Populate grid with items from current category"""
	# Clear existing cards
	for card in item_cards:
		card.queue_free()
	item_cards.clear()

	# Get items for current category
	var items = ShopDatabase.get_items_by_category(current_category)

	# Create card for each item
	for item in items:
		var card_instance = ShopItemCard.new()
		item_grid.add_child(card_instance)
		item_cards.append(card_instance)

		# Setup card
		card_instance.setup(item, player_credits)

		# Connect purchase signal
		card_instance.purchase_requested.connect(_on_purchase_requested)

func _update_credits_display() -> void:
	"""Update credits label"""
	credits_label.text = "💎 %d" % player_credits

func _update_all_cards() -> void:
	"""Update affordability for all cards"""
	for card in item_cards:
		if card.has_method("update_affordability"):
			card.update_affordability(player_credits)

func _on_tab_pressed(category: ShopItem.Category, pressed_button: Button) -> void:
	"""Handle tab button press"""
	if category == current_category:
		return  # Already on this tab

	current_category = category

	# Update button styles
	for child in tab_container.get_children():
		if child is Button:
			child.button_pressed = false
			child.remove_theme_color_override("font_color")

	pressed_button.button_pressed = true
	pressed_button.add_theme_color_override("font_color", NEON_CYAN)

	# Repopulate items
	_populate_items()

func _on_purchase_requested(item: ShopItem) -> void:
	"""Handle purchase attempt"""
	print("[ShopUI] 🛒 Purchase requested: %s (cost: %d)" % [item.display_name, item.cost])

	var game_controller = get_tree().get_first_node_in_group("game_controller")
	if not game_controller:
		push_error("[ShopUI] GameController not found!")
		return

	print("[ShopUI] Current credits: %d, Item cost: %d" % [player_credits, item.cost])

	# Check if can afford
	if not game_controller.can_afford(item.cost):
		print("[ShopUI] ❌ Cannot afford %s (cost: %d, have: %d)" % [item.display_name, item.cost, player_credits])
		return

	# Check if can purchase (not maxed)
	if not item.can_purchase():
		print("[ShopUI] ❌ %s is maxed out" % item.display_name)
		return

	print("[ShopUI] Attempting to spend %d credits..." % item.cost)

	# Spend credits
	if not game_controller.spend_credits(item.cost):
		print("[ShopUI] ❌ Failed to spend credits")
		return

	print("[ShopUI] ✅ Credits spent successfully!")

	# Update local credits
	player_credits = game_controller.get_credits()
	print("[ShopUI] Credits after purchase: %d" % player_credits)
	_update_credits_display()

	# Increment item purchase count
	item.increment_purchases()
	print("[ShopUI] Item purchase count: %d/%d" % [item.current_purchases, item.max_purchases])

	# Apply upgrade via UpgradeManager
	var upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager and upgrade_manager.has_method("purchase_upgrade"):
		print("[ShopUI] Applying upgrade: %s = %.2f" % [item.effect_id, item.effect_value])
		upgrade_manager.purchase_upgrade(item.effect_id, item.effect_value)
	else:
		push_warning("[ShopUI] UpgradeManager not found - upgrade not applied")

	# Update all cards (affordability changed)
	_update_all_cards()

	# Play purchase sound (TODO: integrate with AudioManager)
	print("[ShopUI] ✅ Purchase complete: %s for %d credits" % [item.display_name, item.cost])

func _on_ready_pressed() -> void:
	"""Handle ready button press"""
	print("[ShopUI] Ready button pressed!")
	close_shop()
#endregion
