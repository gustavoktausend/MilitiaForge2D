## Shop Item Card Component
##
## Visual representation of a shop item.
## Shows icon, name, cost, stack count, and buy button.

extends PanelContainer

#region Constants
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
const GRAY: Color = Color(0.3, 0.3, 0.3)
#endregion

#region Signals
signal purchase_requested(item: ShopItem)
#endregion

#region Properties
var item: ShopItem
var can_afford: bool = false
#endregion

#region Node References
var icon_label: Label
var name_label: Label
var description_label: Label
var cost_label: Label
var stack_label: Label
var buy_button: Button
#endregion

func _ready() -> void:
	custom_minimum_size = Vector2(280, 140)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Continue processing when paused
	_create_ui()

func _create_ui() -> void:
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Top row: Icon + Name + Stack
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)

	# Icon
	icon_label = Label.new()
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(40, 40)
	top_row.add_child(icon_label)

	# Name
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", NEON_CYAN)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	# Stack count
	stack_label = Label.new()
	stack_label.add_theme_font_size_override("font_size", 14)
	stack_label.add_theme_color_override("font_color", NEON_YELLOW)
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(stack_label)

	# Description
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(description_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Bottom row: Cost + Buy button
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bottom_row)

	# Cost
	cost_label = Label.new()
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.add_theme_color_override("font_color", NEON_YELLOW)
	bottom_row.add_child(cost_label)

	# Spacer
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(bottom_spacer)

	# Buy button
	buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(80, 32)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.pressed.connect(_on_buy_pressed)
	bottom_row.add_child(buy_button)

#region Public Methods
func setup(shop_item: ShopItem, player_credits: int) -> void:
	"""Initialize card with item data and player credits"""
	item = shop_item
	can_afford = player_credits >= item.cost

	# Update visuals
	icon_label.text = item.icon
	name_label.text = item.display_name
	description_label.text = item.description
	cost_label.text = "💎 %d" % item.cost
	stack_label.text = item.get_stack_text()

	# Update button state
	_update_button_state()

	# Update panel style
	_update_panel_style()

func update_affordability(player_credits: int) -> void:
	"""Update card when player credits change"""
	can_afford = player_credits >= item.cost
	_update_button_state()
	_update_panel_style()
#endregion

#region Private Methods
func _update_button_state() -> void:
	"""Update buy button appearance and state"""
	var is_maxed = item.is_maxed()
	var can_buy = can_afford and item.can_purchase()

	buy_button.disabled = not can_buy or is_maxed

	if is_maxed:
		buy_button.text = "MAX"
		buy_button.add_theme_color_override("font_color", GRAY)
	elif can_afford:
		buy_button.text = "BUY"
		buy_button.add_theme_color_override("font_color", NEON_GREEN)
	else:
		buy_button.text = "BUY"
		buy_button.add_theme_color_override("font_color", NEON_PINK)

func _update_panel_style() -> void:
	"""Update panel border color based on affordability"""
	var is_maxed = item.is_maxed()

	# Create StyleBox with border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	if is_maxed:
		style.border_color = GRAY
	elif can_afford:
		style.border_color = NEON_GREEN
	else:
		style.border_color = NEON_PINK

	add_theme_stylebox_override("panel", style)

func _on_buy_pressed() -> void:
	"""Handle buy button click"""
	print("[ShopItemCard] Buy button pressed for: %s" % (item.display_name if item else "null"))
	if item and can_afford and item.can_purchase():
		print("[ShopItemCard] Emitting purchase_requested signal")
		purchase_requested.emit(item)
	else:
		if not item:
			print("[ShopItemCard] ❌ No item set")
		elif not can_afford:
			print("[ShopItemCard] ❌ Cannot afford (cost: %d)" % item.cost)
		elif not item.can_purchase():
			print("[ShopItemCard] ❌ Item maxed out")
#endregion
