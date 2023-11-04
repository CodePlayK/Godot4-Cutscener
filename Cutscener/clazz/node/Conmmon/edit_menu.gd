@tool
extends VBoxContainer
##节点公共菜单
@onready var node: GraphNode = $"../.."
@onready var index: LineEdit = $MarginContainer/HBoxContainer/Index
@export var index1: Button

##默认标题
var base_text:String
##节点同级运行顺序
var base_index:int=0:
	set(i):
		base_index = max(i,0)
		index.text=str(base_index)
		if index1:
			index1.text = "#" + str(base_index)
			
		
func _ready() -> void:
	base_text = node.title
##更新标题
func _on_title_edit_text_changed(new_text: String) -> void:
	if new_text != "":
		node.title = new_text
	else:
		node.title = base_text
##index+
func _on_plus_button_down() -> void:
	base_index+=1
##index
func _on_min_pressed() -> void:
	base_index-=1
	
func _on_index_text_changed(new_text: String) -> void:
	index.text = str(base_index)
	index.text = str(type_convert(new_text,TYPE_INT))
	base_index=type_convert(new_text,TYPE_INT)
