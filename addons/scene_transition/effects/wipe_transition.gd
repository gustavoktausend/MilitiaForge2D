## WipeTransition - Directional Wipe Effect
##
## Screen wipes in a direction (left, right, up, down).
## Clean and simple transition.

extends TransitionEffect

#region Direction Enum
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN
}
#endregion

#region Configuration
var wipe_direction: Direction = Direction.LEFT
var wipe_color: Color = Color.BLACK
#endregion

#region Private Variables
var _wipe_rect: ColorRect = null
#endregion

func _init(direction: int = 0) -> void:
	super._init()
	wipe_direction = direction as Direction

func _setup() -> void:
	_wipe_rect = ColorRect.new()
	_wipe_rect.color = wipe_color
	_wipe_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wipe_rect)

	# Setup initial position based on direction
	_setup_for_direction()

func _setup_for_direction() -> void:
	match wipe_direction:
		Direction.LEFT:
			_wipe_rect.anchor_top = 0.0
			_wipe_rect.anchor_bottom = 1.0
			_wipe_rect.anchor_left = 0.0
			_wipe_rect.anchor_right = 0.0
			_wipe_rect.size.x = 0
		Direction.RIGHT:
			_wipe_rect.anchor_top = 0.0
			_wipe_rect.anchor_bottom = 1.0
			_wipe_rect.anchor_left = 1.0
			_wipe_rect.anchor_right = 1.0
			_wipe_rect.size.x = 0
		Direction.UP:
			_wipe_rect.anchor_left = 0.0
			_wipe_rect.anchor_right = 1.0
			_wipe_rect.anchor_top = 0.0
			_wipe_rect.anchor_bottom = 0.0
			_wipe_rect.size.y = 0
		Direction.DOWN:
			_wipe_rect.anchor_left = 0.0
			_wipe_rect.anchor_right = 1.0
			_wipe_rect.anchor_top = 1.0
			_wipe_rect.anchor_bottom = 1.0
			_wipe_rect.size.y = 0

## Wipe IN - Cover screen
func _animate_in(tween: Tween, half_duration: float) -> void:
	match wipe_direction:
		Direction.LEFT:
			tween.tween_property(_wipe_rect, "size:x", 1920, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)
		Direction.RIGHT:
			_wipe_rect.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tween.tween_property(_wipe_rect, "size:x", 1920, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)
		Direction.UP:
			tween.tween_property(_wipe_rect, "size:y", 1080, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)
		Direction.DOWN:
			_wipe_rect.grow_vertical = Control.GROW_DIRECTION_BEGIN
			tween.tween_property(_wipe_rect, "size:y", 1080, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(emit_midpoint)

## Wipe OUT - Reveal new scene
func _animate_out(tween: Tween, half_duration: float) -> void:
	match wipe_direction:
		Direction.LEFT, Direction.RIGHT:
			tween.tween_property(_wipe_rect, "size:x", 0, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)
		Direction.UP, Direction.DOWN:
			tween.tween_property(_wipe_rect, "size:y", 0, half_duration)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)

## Allow custom wipe color
func set_wipe_color(color: Color) -> void:
	wipe_color = color
	if _wipe_rect:
		_wipe_rect.color = color
