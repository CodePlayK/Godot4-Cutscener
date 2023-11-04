@tool
extends Button
##吸取向量按钮
@export var target:Control

func _ready() -> void:
	icon = get_theme_icon("ColorPick", "EditorIcons")

func _on_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		Input.set_custom_mouse_cursor(null ,Input.CURSOR_ARROW)
		var nodes = EditorInterface.get_selection().get_selected_nodes()
		if !nodes.is_empty():
			if nodes[0] is Node2D:
				get_parent().get_node(str(target.name)).text = "[%f,%f]" %[nodes[0].global_position.x,nodes[0].global_position.y]
