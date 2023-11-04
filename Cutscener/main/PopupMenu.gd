@tool
extends PopupMenu

func _init() -> void:
	pass

func _ready() -> void:
	preset_add_node_menu()
	
func preset_add_node_menu():
	self.clear()
	for node in CutscenerGlobal.NODE_TYPE.keys():
		if node > 100:continue
		var inst = CutscenerGlobal.NODE_TYPE[node]
		self.add_item("Add [%s] Node" %[inst[1]],node)
	add_separator("operat")
	add_item("合并选中节点 / Combine selected nodes...",101)
