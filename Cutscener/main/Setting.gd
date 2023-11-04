@tool
extends TabContainer
##所有全局变量
var all_globals:Dictionary
@onready var state_tree: Tree = $"Enable Autoloads/TabContainer/StateBus/StateTree"
@onready var method_tree: Tree = $"Enable Autoloads/TabContainer/MethodBus/MethodTree"
const TAB_0 = "配置Autoloads"

func _ready() -> void:
	CutscenerGlobal.refresh_setting_autoload_config.connect(on_refresh_setting_autoload_config)
	set_tab_title(0,TAB_0)

##刷新setting中的autoload列表		
func on_refresh_setting_autoload_config():
	load_all_global(method_tree,CutscenerGlobal.CONFIG_DATA_DIC["method_bus"])
	load_all_global(state_tree,CutscenerGlobal.CONFIG_DATA_DIC["state_bus"])	
	CutscenerGlobal.load_all_method_state_from_global.emit()	
	
func load_all_global(global_tree:Tree,list:Array):
	var project = ConfigFile.new()
	var err = project.load("res://project.godot")
	assert(err == OK, "Could not find the project file")
	all_globals.clear()
	if project.has_section("autoload"):
		for key in project.get_section_keys("autoload"):
			if key != "CutscenerGlobal" and get_tree().get_root().has_node(key):
				all_globals[key] = project.get_value("autoload", key)
	global_tree.clear()
	var root = global_tree.create_item()
	for name in all_globals.keys():
		var item: TreeItem = global_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		if list and !list.is_empty():
			item.set_checked(0, name in list)
		item.set_text(0, name)
		item.add_button(1, get_theme_icon("Edit", "EditorIcons"))
		item.set_text(2, all_globals.get(name, "").replace("*res://", "res://"))
	global_tree.set_column_expand(0, false)
	global_tree.set_column_custom_minimum_width(0, 250)
	global_tree.set_column_expand(1, false)
	global_tree.set_column_custom_minimum_width(1, 40)
	global_tree.set_column_title(0, "Autoload")
	global_tree.set_column_title(1, "打开")
	global_tree.set_column_title(2, "Path")
	global_tree.set_column_titles_visible(true)
	
func _on_method_tree_item_selected() -> void:
	set_tree_selected(method_tree,CutscenerGlobal.CONFIG_DATA_DIC["method_bus"])

func set_tree_selected(global_tree:Tree,list:Array):
	var item = global_tree.get_selected()
	var is_checked = not item.is_checked(0)
	item.set_checked(0, is_checked)
	if is_checked:
		list.append(item.get_text(0))
	else:
		list.erase(item.get_text(0))

func _on_state_tree_item_mouse_selected(position: Vector2, mouse_button_index: int) -> void:
	set_tree_selected(state_tree,CutscenerGlobal.CONFIG_DATA_DIC["state_bus"])

func _on_method_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	EditorInterface.edit_resource(load(item.get_text(2)))
