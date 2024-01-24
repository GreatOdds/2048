extends Control

#region Node Exports
@export
var ui_grid : UIGrid
@export
var score_label: Label
@export
var best_score_label: Label
@export
var new_game_button: Button
@export
var new_game_confirmation_dialog: ConfirmationDialog
@export
var over_confirmation_dialog: ConfirmationDialog
@export
var won_confirmation_dialog: ConfirmationDialog
#endregion

var game : Game

var _accepting_input := true
var _save_data : SaveData

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false

	_save_data = SaveData.load()
	_save_data.changed.connect(_on_best_score_changed)

	if ui_grid:
		ui_grid.update_completed.connect(_on_ui_update_completed)

	if score_label:
		score_label.text = _format_score(0)

	if best_score_label:
		var best_score := _save_data.best_score if _save_data else 0
		best_score_label.text = _format_score(best_score)

	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_button_pressed)

	if new_game_confirmation_dialog:
		new_game_confirmation_dialog.confirmed.connect(_on_new_game_requested)

	if over_confirmation_dialog:
		over_confirmation_dialog.confirmed.connect(_on_new_game_requested)

	if won_confirmation_dialog:
		won_confirmation_dialog.confirmed.connect(_on_new_game_requested)
		won_confirmation_dialog.canceled.connect(_on_continue_game_requested)

	game = Game.new()
	game.over.connect(_on_game_over)
	game.won.connect(_on_game_won)
	game.score_changed.connect(_on_game_score_changed)
	game.changed.connect(_on_game_changed)
	game.start()

func _draw() -> void:
	pass

func _unhandled_input(p_event: InputEvent) -> void:
	if not game or not _accepting_input:
		return
	if p_event.is_action_pressed("ui_up"):
		game.move(Game.Directions.UP)
	elif p_event.is_action_pressed("ui_down"):
		game.move(Game.Directions.DOWN)
	elif p_event.is_action_pressed("ui_left"):
		game.move(Game.Directions.LEFT)
	elif p_event.is_action_pressed("ui_right"):
		game.move(Game.Directions.RIGHT)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_WM_CLOSE_REQUEST:
			SaveData.save(_save_data)
			get_tree().quit()

func _format_score(p_score: int) -> String:
	if p_score > 999_999:
		return "%.1fm" % (p_score / 1000_000.0)
	elif p_score > 999:
		return "%.1fk" % (p_score / 1000.0)
	return "%d" % p_score

#region Signal Connections
func _on_game_over() -> void:
	if over_confirmation_dialog:
		over_confirmation_dialog.popup_centered()
	_accepting_input = false

func _on_game_won() -> void:
	if won_confirmation_dialog:
		won_confirmation_dialog.popup_centered()

func _on_game_score_changed(p_score: int) -> void:
	if score_label:
		score_label.text = _format_score(p_score)
	if _save_data and p_score > _save_data.best_score:
		_save_data.best_score = p_score

func _on_game_changed(p_grid: GameGrid) -> void:
	if not ui_grid:
		return
	if ui_grid.do_animation:
		_accepting_input = false
	ui_grid.update(p_grid)

func _on_best_score_changed() -> void:
	if best_score_label and _save_data:
		best_score_label.text = _format_score(_save_data.best_score)

func _on_ui_update_completed() -> void:
	_accepting_input = true

func _on_new_game_button_pressed() -> void:
	if new_game_confirmation_dialog:
		new_game_confirmation_dialog.popup_centered()

func _on_new_game_requested() -> void:
	if score_label:
		score_label.text = _format_score(0)
	game.start()
	_accepting_input = true

func _on_continue_game_requested() -> void:
	_accepting_input = true
	game._should_continue = true
#endregion
