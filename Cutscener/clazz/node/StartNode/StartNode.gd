@tool
extends BaseGraphNode
@onready var start: Button = $main/VBC/HBC/Start
@onready var file_name: LineEdit = $main/VBC/HBC/FileName

func ready() -> void:
	start.icon = get_theme_icon("Play","EditorIcons")

func init_var():
	node_type=CutscenerGlobal.NODES.START_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["StartNode",self.title]
	
func load_save(combine_node_name:String = "NA",dic_raw:Dictionary = {}):
	file_name.text = CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]
	pass

func _on_start_pressed() -> void:
	CutscenerGlobal.WORK_SPACE._on_run_pressed()
