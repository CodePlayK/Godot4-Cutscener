@tool
extends Button
@onready var combine_node: GraphNode = $"../../../../.."

func _on_pressed() -> void:
	CutscenerGlobal.discombine_node.emit(combine_node)
	pass 
