@tool
class_name UITile
extends Control

const bg_colors: Array[Color] = [
	Color("#eee4da"), # 2    # 0b000000000010
	Color("#ede0c8"), # 4    # 0b000000000100
	Color("#f2b179"), # 8    # 0b000000001000
	Color("#f59563"), # 16   # 0b000000010000
	Color("#f67c5f"), # 32   # 0b000000100000
	Color("#f65e3b"), # 64   # 0b000001000000
	Color("#edcf72"), # 128  # 0b000010000000
	Color("#edcc61"), # 256  # 0b000100000000
	Color("#edc850"), # 512  # 0b001000000000
	Color("#edc53f"), # 1024 # 0b010000000000
	Color("#edc22e"), # 2048 # 0b100000000000
	]
const fg_colors: Array[Color] = [
	Color("#776e65"), # 2
	Color("#776e65"), # 4
	Color("#f9f6f2"), # 8
	Color("#f9f6f2"), # 16
	Color("#f9f6f2"), # 32
	Color("#f9f6f2"), # 64
	Color("#f9f6f2"), # 128
	Color("#f9f6f2"), # 256
	Color("#f9f6f2"), # 512
	Color("#f9f6f2"), # 1024
	Color("#f9f6f2"), # 2048
	]

@export
var value := 2: set = set_value
@export
var max_font_size := 64: set = set_max_font_size

var _font      : Font
var _style_box : StyleBox
var _font_size : int
var _bg_color := Color.BLACK
var _fg_color := Color.WHITE

func _init() -> void:
	_recalculate_colors()
	_update_theme_item()
	resized.connect(_on_resized)

func _enter_tree() -> void:
	_update_theme_item()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_update_theme_item()

func _draw() -> void:
	var tl_ofs := Vector2.ZERO
	var br_ofs := Vector2.ZERO
	if _style_box:
		tl_ofs.x = _style_box.content_margin_left
		tl_ofs.y = _style_box.content_margin_top
		br_ofs.x = _style_box.content_margin_right
		br_ofs.y = _style_box.content_margin_bottom
		if _style_box is StyleBoxFlat:
			_style_box.bg_color = _bg_color
		draw_style_box(_style_box, Rect2(Vector2.ZERO, size))
	if _font:
		var text := "%d" % value
		var draw_size := size - tl_ofs - br_ofs
		var text_size := _font.get_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)
		draw_string(
			_font,
			0.5 * Vector2(
				draw_size.x - text_size.x,
				draw_size.y + text_size.y * 0.5) + tl_ofs,
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			_font_size,
			_fg_color)

func set_value(p_value: int) -> void:
	value = maxi(p_value, 0)
	_recalculate_colors()
	_recalculate_font_size()

func set_max_font_size(p_max_font_size: int) -> void:
	max_font_size = maxi(p_max_font_size, 1)
	_recalculate_font_size()

func _update_theme_item() -> void:
	_font = get_theme_font("font", "Label")
	_style_box = get_theme_stylebox("panel", "Panel")
	_style_box = _style_box.duplicate()
	_recalculate_font_size()

func _on_resized() -> void:
	_recalculate_font_size()

func _recalculate_colors() -> void:
	if value <= 0 or bg_colors.size() <= 0 or fg_colors.size() <= 0:
		return
	var max_size := mini(bg_colors.size(), fg_colors.size())
	var idx := 0
	while value & (0b10 << idx) <= 0 and idx < 63:
		idx += 1
	idx = clampi(idx, 0, maxi(max_size-1, 0))
	_bg_color = bg_colors[idx]
	_fg_color = fg_colors[idx]

func _recalculate_font_size() -> void:
	var tl_ofs := Vector2.ZERO
	var br_ofs := Vector2.ZERO
	if _style_box:
		tl_ofs.x = _style_box.content_margin_left
		tl_ofs.y = _style_box.content_margin_top
		br_ofs.x = _style_box.content_margin_right
		br_ofs.y = _style_box.content_margin_bottom
	var draw_size := size - tl_ofs - br_ofs
	_font_size = max_font_size
	var text := "%d" % value
	var text_size := _font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)
	while _font_size > 1 and (text_size.x > draw_size.x or text_size.y > draw_size.y):
		_font_size -= 1
		text_size = _font.get_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)
	queue_redraw()
