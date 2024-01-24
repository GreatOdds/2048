class_name Game
extends RefCounted

signal score_changed(score: int)
signal changed(grid: GameGrid)
signal over()
signal won()

enum Directions {UP, DOWN, LEFT, RIGHT}

var starting_tiles := 2
var winning_value := 2048

var score := 0
var _is_over := false
var _is_won  := false
var _should_continue := false

var _grid : GameGrid
var _rng : RandomNumberGenerator

func start(p_size := Vector2i(4, 4), p_seed := -1) -> void:
	if p_size.x <= 0 or p_size.y <= 0:
		return

	if not _rng:
		_rng = RandomNumberGenerator.new()
	if p_seed == -1:
		_rng.randomize()
	else:
		_rng.seed = p_seed

	_grid = GameGrid.new(p_size)
	score = 0
	_is_over = false
	_is_won  = false
	_should_continue = false
	_spawn_starting_tiles()
	changed.emit(_grid)

func _spawn_starting_tiles() -> void:
	for i in starting_tiles:
		_spawn_random_tile()

func _spawn_random_tile() -> void:
	if not _rng:
		return
	var empty_cells := _grid.get_empty_cells()
	if empty_cells.is_empty():
		return
	var value := 2 if _rng.randf() < 0.9 else 4
	var tile := GameTile.new(
		value, empty_cells[_rng.randi() % empty_cells.size()])
	_grid.set_cell(tile.cell, tile)

func move(p_direction: Directions) -> void:
	if not _grid or _is_terminated():
		return
	var old_score := score

	_prepare_tiles()
	var was_moved := false
	var movement  := _get_movement(p_direction)

	for x in _generate_indices(_grid.size.x, movement.x == 1):
		for y in _generate_indices(_grid.size.y, movement.y == 1):
			var cell := Vector2i(x, y)
			var tile := _grid.get_cell(cell)
			if not tile:
				continue
			var furthest := _get_furthest_cell(cell, movement)
			var next := _grid.get_cell(furthest + movement)
			if next and next.value == tile.value and next.merged_from.is_empty():
				next.value *= 2
				next.merged_from = [tile.prev_cell, next.prev_cell]
				_grid.set_cell(cell, null)
				score += next.value
				if next.value == winning_value:
					_is_won = true
				was_moved = true
			elif cell != furthest:
				_grid.set_cell(cell, null)
				tile.cell = furthest
				_grid.set_cell(furthest, tile)
				was_moved = true

	if was_moved:
		_spawn_random_tile()
		if not _has_moves_available():
			_is_over = true
			over.emit()
		if old_score != score:
			score_changed.emit(score)
		changed.emit(_grid)

	if _is_won and not _should_continue:
		won.emit()

func _is_terminated() -> bool:
	return _is_over or (_is_won and not _should_continue)

func _prepare_tiles() -> void:
	var threads: Array[Thread] = []
	for y in _grid.size.y:
		var thread := Thread.new()
		thread.start(_prepare_row.bind(y, _grid.size.x))
		threads.push_back(thread)
	for thread in threads:
		thread.wait_to_finish()

func _prepare_row(p_row: int, p_size: int) -> void:
	for x in p_size:
		var tile := _grid.get_cell(Vector2i(x, p_row))
		if tile:
			tile.just_spawned = false
			tile.merged_from.clear()
			tile.save_cell()

func _get_movement(p_direction: Directions) -> Vector2i:
	match p_direction:
		Directions.UP:
			return Vector2i( 0,-1)
		Directions.DOWN:
			return Vector2i( 0, 1)
		Directions.LEFT:
			return Vector2i(-1, 0)
		Directions.RIGHT,_:
			return Vector2i( 1, 0)

func _get_furthest_cell(p_cell: Vector2i, p_movement: Vector2i) -> Vector2i:
	var prev : Vector2i
	var valid := true
	while valid:
		prev    = p_cell
		p_cell += p_movement
		valid = _grid.is_in_bounds(p_cell) and not _grid.get_cell(p_cell)
	return prev

func _generate_indices(p_size: int, p_reverse := false) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for i in p_size:
		indices.push_back(i)
	if p_reverse:
		indices.reverse()
	return indices

func _has_moves_available() -> bool:
	return (_grid.cells.find(null) != -1) or _has_matches_available()

func _has_matches_available() -> bool:
	for x in _grid.size.x:
		for y in _grid.size.y:
			var cell := Vector2i(x, y)
			var tile := _grid.get_cell(cell)
			if not tile:
				continue
			var right := _grid.get_cell(cell + Vector2i(1, 0))
			if right and right.value == tile.value:
				return true
			var down := _grid.get_cell(cell + Vector2i(0, 1))
			if down and down.value == tile.value:
				return true
	return false
