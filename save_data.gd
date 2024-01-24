class_name SaveData
extends Resource

const SAVE_PATH := "user://save.tres"

@export
var best_score := 0: set = set_best_score

func set_best_score(p_best_score: int) -> void:
	best_score = maxi(p_best_score, 0)
	changed.emit()

static func load() -> SaveData:
	var save_data := ResourceLoader.load(SAVE_PATH) as SaveData
	if not save_data:
		save_data = SaveData.new()
		SaveData.save(save_data)
	return save_data

static func save(p_save_data: SaveData) -> void:
	if not p_save_data:
		return
	ResourceSaver.save(p_save_data, SAVE_PATH)

static func reset() -> void:
	var save_data := SaveData.load()
	save_data.best_score = 0
	SaveData.save(save_data)
