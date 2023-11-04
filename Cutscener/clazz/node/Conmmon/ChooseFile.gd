@tool
extends Button
signal choose_file
@export var node:Control

func _ready() -> void:
	icon = get_theme_icon("FileDialog", "EditorIcons")

func _on_pressed() -> void:
	CutscenerGlobal.WORK_SPACE.node_file_dialog.show()
	if !CutscenerGlobal.WORK_SPACE.node_file_dialog.file_selected.is_connected(set_choose_file_path):
		CutscenerGlobal.WORK_SPACE.node_file_dialog.file_selected.connect(set_choose_file_path)

func set_choose_file_path(path):
	get_parent().get_node(str(node.name)).text = path
	if CutscenerGlobal.WORK_SPACE.node_file_dialog.file_selected.is_connected(set_choose_file_path):
		CutscenerGlobal.WORK_SPACE.node_file_dialog.file_selected.disconnect(set_choose_file_path)
