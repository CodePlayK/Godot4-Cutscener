@tool
##全局变量列表
##
##当光标在{{}}中时快速输入变量名
extends ItemList
##当前的输入框
var current_line_edit:LineEdit
##所有变量
var state_list:Array
@onready var side_bar: VBoxContainer = $".."
##当前选中的文本框中每一对{{}}的位置列表
##[[第1个{{的位置,第1个}}的位置],[第2个{{的位置,第2个}}的位置...]
var markers:Array

func _ready() -> void:
	CutscenerGlobal.load_global.connect(on_load_global)
	CutscenerGlobal.param_modify.connect(on_param_modify)
	CutscenerGlobal.param_focus_enter.connect(on_param_focus_enter)
	CutscenerGlobal.param_focus_exit.connect(on_param_focus_exit)

##在选中了文本框而且光标位于{{}}中时,用ALT+↑↓快速选择变量名
func _unhandled_key_input(event: InputEvent) -> void:
	if !current_line_edit or !current_line_edit.has_focus():return
	if !event.is_action_pressed("ui_down") and !event.is_action_pressed("ui_up"):return
	if Input.is_key_pressed(KEY_ALT) and Input.is_action_just_pressed("ui_down"):
		if is_anything_selected():
			var index = min(max(get_selected_items()[0]+1,0),item_count-1)
			select(index)
			_on_item_activated(index)
		elif item_count>0 :
			select(0)
			_on_item_activated(0)
	elif Input.is_key_pressed(KEY_ALT) and Input.is_action_just_pressed("ui_up"):
		if is_anything_selected():
			var index = min(max(get_selected_items()[0]-1,0),item_count-1)
			select(index)
			_on_item_activated(index)
		elif item_count>0:
			select(0)
			_on_item_activated(0)
##全局脚本载入完成事件
func on_load_global() -> void:
	clear()
	state_list.clear()
	for bus in CutscenerGlobal.STATE_BUSES:
		var prop_list:Array =get_tree().get_root().get_node(bus).get_property_list()
		for i in prop_list.size():
			if i > 18:
				var prop = prop_list[i]
				state_list.append(prop["name"])
				add_item(prop["name"])
##文本框编辑事件
func on_param_modify(text:String) -> void:
	var list= []
	var real_text=""
	get_markers(text,0,list)
	markers = list.duplicate(true)
	for m in list:
		if current_line_edit.caret_column >=m[0] and current_line_edit.caret_column <=m[1]:
			real_text = text.substr(m[0],m[1]-m[0])
			break
	clear()
	real_text = real_text.replace("{","").replace("}","").replace(" ","")
	for state:String in state_list:
		if real_text == "" or state.to_lower().contains(real_text.to_lower()):
			add_item(state)
	if item_count > 0:
		select(0)
		
##文本框选中事件
func on_param_focus_enter(line_edit:LineEdit) -> void:
	current_line_edit = line_edit
	reset()
	
##文本框离开事件
func on_param_focus_exit() -> void:
	current_line_edit = null

##初始化
func reset():
	clear()
	for state in state_list:
		add_item(state)

##选中事件
func _on_item_activated(index: int) -> void:
	refrsh_markers()
	if !side_bar.visible or !current_line_edit:return
	if  current_line_edit.text.is_empty():
		current_line_edit.text = "{{" + get_item_text(index) + "}}"
		current_line_edit.select(2,2+get_item_text(index).length())
	if current_line_edit.has_selection():
		var text:String = current_line_edit.text
		var selection = current_line_edit.get_selected_text()
		var from =  current_line_edit.get_selection_from_column()
		var to =  current_line_edit.get_selection_to_column()
		var begin = text.substr(0,from)
		var end = text.substr(to,text.length()-1)
		if begin.ends_with("{{") and end.begins_with("}}"):
			current_line_edit.text = begin + get_item_text(index) + end
			current_line_edit.select(from,from+get_item_text(index).length())
	else :
		if !markers.is_empty():
			for m in markers:
				if current_line_edit.caret_column >=m[0] and current_line_edit.caret_column <=m[1]:
					current_line_edit.text = current_line_edit.text.erase(m[0],m[1]-m[0])
					var t = get_item_text(index)
					current_line_edit.text = current_line_edit.text.insert(m[0],t)
					current_line_edit.select(m[0],m[0]+t.length())
					break
	refrsh_markers()

##获取当前文本框中所有{{}}对的位置
func get_markers(text:String,from_i:int,list:Array):
	var fm_index =text.findn("{{",from_i)
	var tm_index =text.findn("}}",fm_index)
	if tm_index!= -1 and fm_index!= -1:
		list.append([fm_index+2,tm_index])
	if text.find("{{",tm_index)!=-1:
		get_markers(text,tm_index,list)

##刷新
func refrsh_markers():
	var list=[]
	if current_line_edit:
		get_markers(current_line_edit.text,0,list)
	markers = list.duplicate(true)

func _on_item_selected(index: int) -> void:
	refrsh_markers()
