@tool
extends Button
@onready var combine_node: GraphNode = $"../../../../.."


func _on_pressed() -> void:
	var path = ProjectSettings.globalize_path(combine_node.save_file_name.get_base_dir())
	OS.shell_open(path)
