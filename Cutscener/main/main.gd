@tool
extends MarginContainer
class_name Cutscener
@onready var sidebar: Button = $VBoxContainer/MenuBar/sidebar
@onready var save: Button = $VBoxContainer/MenuBar/save
@onready var save_as: Button = $VBoxContainer/MenuBar/save_as
@onready var open: Button = $VBoxContainer/MenuBar/open
@onready var new: Button = $VBoxContainer/MenuBar/new
@onready var run: Button = $VBoxContainer/MenuBar/run
@onready var load: Button = $VBoxContainer/MenuBar/load
@onready var setting: Button = $VBoxContainer/MenuBar/setting
@onready var run_project: Button = $VBoxContainer/MenuBar/run_config/run_project
@onready var rearrange: Button = $VBoxContainer/MenuBar/rearrange
@onready var file_history: ItemList = $VBoxContainer/WorkSpace/SideBar/FileHistory
@onready var label: Button = $VBoxContainer/WorkSpace/SideBar/Label
@onready var label_2: Button = $VBoxContainer/WorkSpace/SideBar/Label2

func _ready() -> void:
	CutscenerGlobal.refresh_setting_autoload_config.emit()
	save.icon = get_theme_icon("Save", "EditorIcons")
	save_as.icon = get_theme_icon("FileAccess", "EditorIcons")
	open.icon = get_theme_icon("Load", "EditorIcons")
	new.icon = get_theme_icon("New", "EditorIcons")
	run.icon = get_theme_icon("MainPlay", "EditorIcons")
	load.icon = get_theme_icon("Reload", "EditorIcons")
	setting.icon = get_theme_icon("Tools", "EditorIcons")
	run_project.icon = get_theme_icon("MainPlay", "EditorIcons")
	rearrange.icon = get_theme_icon("Grid", "EditorIcons")
	sidebar.icon = get_theme_icon("Back", "EditorIcons")
	label.icon = get_theme_icon("History", "EditorIcons")
	label_2.icon = get_theme_icon("Variant", "EditorIcons")
	file_history.clear()
	save_config_file()
	
func _on_tree_exited() -> void:
	CutscenerGlobal.preset()
	

func save_config_file():
	if FileAccess.file_exists(CutscenerGlobal.CONFIG_DATA_FILE_PATH):
		return
	CutscenerGlobal.ACTION_LOG = "config.data不存在,新建..."
	DirAccess.make_dir_absolute(CutscenerGlobal.CONFIG_DATA_FILE_PATH.get_base_dir())#确保文件目录存在
	var config = FileAccess.open(CutscenerGlobal.CONFIG_DATA_FILE_PATH, FileAccess.WRITE)
	config.store_line(JSON.stringify(CutscenerGlobal.CONFIG_DATA_DIC,"\t"))
