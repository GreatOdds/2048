class_name GameTile
extends RefCounted

const INT64_MAX := (1 << 63) - 1

var value        : int
var cell         : Vector2i
var prev_cell    : Vector2i
var merged_from  : Array[Vector2i] = []
var just_spawned : bool

func _init(p_value: int, p_cell: Vector2i, p_merged_from: Array[Vector2i] = []) -> void:
	value = clampi(p_value, 0, INT64_MAX)
	cell = p_cell.clamp(Vector2i.ZERO, Vector2i.MAX)
	merged_from = p_merged_from
	just_spawned = true

func save_cell() -> void:
	prev_cell = cell
