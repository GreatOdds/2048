class_name UIGrid
extends Control

signal update_completed()

@export
var do_animation := true
@export
var animation_time := 0.15
@export
var spacing := Vector2(0.01, 0.01)

var _dead : Array[UITile] = []
var _live : Array[UITile] = []

func update(p_grid: GameGrid) -> void:
	_kill_all()
	if p_grid.size.x <= 0 or p_grid.size.y <= 0:
		return
	# total size is 1, 1
	var tile_anchor_size := _calculate_tile_anchor_size(p_grid.size)
	for tile in p_grid.cells:
		if not tile:
			continue

		var ui_tile := _get_dead_tile()
		ui_tile.value = tile.value
		var end_anchor_tl := (tile_anchor_size + spacing) * Vector2(tile.cell)
		var end_anchor_br := end_anchor_tl + tile_anchor_size

		if not do_animation:
			UIGrid._assign_anchors(ui_tile, end_anchor_tl.x, end_anchor_tl.y,
				end_anchor_br.x, end_anchor_br.y)
			continue

		var start_anchor_tl := Vector2.ZERO
		var start_anchor_br := Vector2.ZERO
		if tile.just_spawned:
			start_anchor_tl = end_anchor_tl + tile_anchor_size * 0.5
			start_anchor_br = start_anchor_tl
		elif tile.merged_from.size() >= 2:
			var a := tile.merged_from[0]
			var b := tile.merged_from[1]
			var min_cell := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
			var max_cell := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
			start_anchor_tl = (tile_anchor_size + spacing) * Vector2(min_cell)
			start_anchor_br = (tile_anchor_size + spacing) * Vector2(max_cell) + tile_anchor_size
		else:
			start_anchor_tl = (tile_anchor_size + spacing) * Vector2(tile.prev_cell)
			start_anchor_br = start_anchor_tl + tile_anchor_size

		_animate_tile(
			ui_tile,
			start_anchor_tl,
			start_anchor_br,
			end_anchor_tl,
			end_anchor_br)
	if do_animation:
		await get_tree().create_timer(animation_time, false).timeout
	update_completed.emit()

func _get_dead_tile() -> UITile:
	if _dead.is_empty():
		return _spawn_new_tile()
	var idx := _dead.size() - 1
	var tile := _dead[idx]
	_dead.remove_at(idx)
	tile.visible = true
	tile.process_mode = Node.PROCESS_MODE_INHERIT
	_live.push_back(tile)
	return tile

func _spawn_new_tile() -> UITile:
	var new_tile := UITile.new()
	new_tile.visible = true
	new_tile.process_mode = Node.PROCESS_MODE_INHERIT
	_live.push_back(new_tile)
	add_child(new_tile, false, Node.INTERNAL_MODE_FRONT)
	return new_tile

func _kill(p_tile: UITile) -> void:
	_live.erase(p_tile)
	p_tile.visible = false
	p_tile.process_mode = Node.PROCESS_MODE_DISABLED
	_dead.push_back(p_tile)

func _kill_all() -> void:
	var sz := _live.size()
	if sz == 0:
		return
	for i in sz:
		var idx := sz - 1 - i
		var tile := _live[idx]
		_live.remove_at(idx)
		tile.visible = false
		tile.process_mode = Node.PROCESS_MODE_DISABLED
		_dead.push_back(tile)

static func _assign_anchors(
		p_control: Control,
		p_left: float,
		p_top: float,
		p_right: float,
		p_bottom: float) -> void:
	p_control.anchor_left   = p_left
	p_control.anchor_top    = p_top
	p_control.anchor_right  = p_right
	p_control.anchor_bottom = p_bottom

func _animate_tile(
		p_tile: Control,
		p_start_tl: Vector2,
		p_start_br: Vector2,
		p_end_tl: Vector2,
		p_end_br: Vector2) -> void:
	UIGrid._assign_anchors(
		p_tile, p_start_tl.x, p_start_tl.y, p_start_br.x, p_start_br.y)
	var tweener := p_tile.create_tween()
	tweener.set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tweener.tween_property(p_tile, "anchor_left", p_end_tl.x, animation_time)
	tweener.tween_property(p_tile, "anchor_top", p_end_tl.y, animation_time)
	tweener.tween_property(p_tile, "anchor_right", p_end_br.x, animation_time)
	tweener.tween_property(p_tile, "anchor_bottom", p_end_br.y, animation_time)

func _calculate_tile_anchor_size(p_grid_size: Vector2) -> Vector2:
	var total_spacing_size := spacing * (p_grid_size - Vector2.ONE).clamp(
		Vector2.ZERO, Vector2.INF)
	var tile_anchor_size := (Vector2.ONE - total_spacing_size) / p_grid_size
	return tile_anchor_size
