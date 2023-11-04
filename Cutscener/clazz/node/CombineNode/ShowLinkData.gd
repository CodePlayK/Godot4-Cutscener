@tool
extends Button
var flag =true
@onready var combine_node: GraphNode = $"../../../../.."

func _on_pressed() -> void:
	combine_node.show_all_link_data(flag)
	flag=!flag
	combine_node.size.x=0
