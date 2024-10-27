class_name LevelManager extends Node

@export_file("*.tscn") var _game_over_scene: String
@export_file("*.tscn") var _clear_level_scene: String

func OnGameOver() -> void:
	if (_game_over_scene):
		get_tree().change_scene_to_file(_game_over_scene);
	else:
		get_tree().reload_current_scene();
		
func OnLevelCleared() -> void:
	if (_clear_level_scene):
		get_tree().change_scene_to_file(_clear_level_scene);
	else:
		get_tree().reload_current_scene();
