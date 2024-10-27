extends Button

@export_file("*.tscn") var _target_level: String

func OnPressed() -> void:
	print(_target_level)
	if (!_target_level):
		return;
		
	get_tree().change_scene_to_file(_target_level);
