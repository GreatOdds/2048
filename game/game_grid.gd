class_name GameGrid
extends RefCounted

var size  : Vector2i: set = set_size
var cells : Array[GameTile] = []

func _init(p_size : Vector2i) -> void:
	set_size(p_size)

func set_size(p_size: Vector2i) -> void:
	size = p_size.clamp(Vector2i.ONE, Vector2i.MAX)
	clear()

func set_cell(p_cell: Vector2i, p_tile: GameTile) -> void:
	cells[p_cell.x + size.x * p_cell.y] = p_tile

func get_cell(p_cell: Vector2i) -> GameTile:
	if is_in_bounds(p_cell):
		return cells[p_cell.x + size.x * p_cell.y]
	return null

func get_empty_cells() -> Array[Vector2i]:
	var empty_cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if not get_cell(cell):
				empty_cells.push_back(cell)
	return empty_cells

func is_in_bounds(p_cell: Vector2i) -> bool:
	return (p_cell.x >= 0 and p_cell.x < size.x and
			p_cell.y >= 0 and p_cell.y < size.y)

func clear() -> void:
	cells.clear()
	cells.resize(size.x * size.y)
