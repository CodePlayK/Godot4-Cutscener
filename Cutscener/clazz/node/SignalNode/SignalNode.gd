@tool
extends BaseGraphNode
@onready var param_prototype: HBoxContainer = $main/ParamPrototype
@onready var param: VBoxContainer = $main/VBC/Param
@onready var runner: Node = $runner
@onready var param_type: OptionButton = $main/ParamPrototype/ParamType
@onready var signal_list: OptionButton = $main/VBC/Signal/SignalName/SignalList
@onready var choose_vec2: Button = $main/ParamPrototype/ChooseVec2
@onready var choose_file: Button = $main/ParamPrototype/ChooseFile
@onready var signal_node: GraphNode = $"."
@onready var export: CheckButton = $main/ParamPrototype/Export
@onready var icon: Button = $main/VBC/Signal/SignalName/Icon

##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	ParamIndex = 0,
	ParamTypeIndex = 1,
	Param2Index = 2,
	ExportIndex = 3,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX {
	LabelIndex = 0,
	ParamIndex = 1,
	ParamTypeIndex = 2,
	Param2Index = 3,
	DeleteParamIndex = 4,
	ChooseFileIndex = 5,
	ChooseVec2Index = 6,
	ExportIndex = 7,
}
const LABEL_PRESET = "#"
##当前参数个数
var param_ct:int = 1:
	set(i):
		props = param.get_children()
		param_ct=props.size()
		refrsh_index_label()
##存档数据
var props:Array
##当前方法返回值是否为bool
var is_condition_method:bool:
	set(f):
		is_condition_method = f
		set_condition_method(f)
		
##配置多选节点		
func set_condition_method(flag:bool):
	signal_node.set_slot_enabled_right(1,flag)
	if flag:
		signal_node.set_slot_color_right(0,CutscenerGlobal.slot_true_color)
		signal_node.set_slot_color_right(1,CutscenerGlobal.slot_false_color)
	else :
		signal_node.set_slot_color_right(0,CutscenerGlobal.slot_default_color)
	
func init_var():
	node_type=CutscenerGlobal.NODES.SIGNAL_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["SignalNode",self.title]
	
func ready():
	icon.icon = get_theme_icon("PlayStart","EditorIcons")
	param_type.clear()
	for type in CutscenerGlobal.VAR_TYPE.values():
		param_type.add_item(CutscenerGlobal.VAR_TYPE_DIC[type][0],type)
		param_type.set_item_disabled(get_index_by_id(param_type,type),true)

##获取存档数据
func get_save(is_saving_other:bool=false):
	param_ct=1
	var params:Array
	for i in props.size():
		var pc = props[i].get_children()
		##[[Param,ParamType,Param2,参数1是否导出0/1],是否导出必须为最后一位
		var args = [
			pc[CONTROL_INDEX.ParamIndex].text,#Param
			pc[CONTROL_INDEX.ParamTypeIndex].get_selected_id(),#ParamType
			pc[CONTROL_INDEX.Param2Index].text,#Param2
			pc[CONTROL_INDEX.ExportIndex].is_export#参数1是否导出
		]
		params.append(args)
		for p_name in node_save_data.keys():
			if p_name.contains("props") and node_save_data[p_name].size()> i:
				var prop = node_save_data[p_name][i]
				node_save_data[p_name][i][3] = pc[7].is_export
	node_save_data["props"] = params
	node_save_data["return_type"] = is_condition_method
	node_save_data["signal_name"] = signal_list.get_item_text(signal_list.get_selected_id())
	return node_save_data

##载入存档	
func load_save(combine_node_name:String = "NA",dic_raw:Dictionary = {}):
	await clean_all_param()
	var params:Array
	for i in signal_list.get_item_count():
		if signal_list.get_item_text(i)==node_save_data["signal_name"]:
			signal_list.select(i)
			break
	var props:Array = node_save_data["props"]
	if !combine_node_name=="NA" and node_save_data.has(combine_node_name+"_props"):
		props = node_save_data[combine_node_name+"_props"]
		CutscenerGlobal.ACTION_LOG = "[%s]载入聚合node数据覆盖!" %self.name
	new_param(props)
	
##移除参数字段	
func _on_delete_param_remove_param(obj) -> void:
	obj.queue_free()
	await obj.tree_exited
	param_ct-=1
	
##更新标签数字	
func refrsh_index_label():
	for i in props.size():
		props[i].get_children()[0].text = LABEL_PRESET + str(i+1)
	self.size.y=0
	
##新参数列	[Param,ParamType,Param2,参数1是否导出0/1]
func new_param(p_list):
	for p in p_list:
		var pn = param_prototype.duplicate()
		var label = pn.get_node("Label")
		var Param = pn.get_node("Param")
		var Param2 = pn.get_node("Param2")
		var ChooseVec2 = pn.get_node("ChooseVec2")
		var ChooseFile = pn.get_node("ChooseFile")
		var ParamType = pn.get_node("ParamType")
		var Export = pn.get_node("Export")
		Param2.text = str(p[ARGS_INDEX.Param2Index])
		Param.text = str(p[ARGS_INDEX.ParamIndex])
		var type =  p[ARGS_INDEX.ParamTypeIndex]
		if type==TYPE_VECTOR2:
			ChooseVec2.show()
		elif type==TYPE_OBJECT:
			ChooseFile.show()
		if p.size()>=4:
			if p[ARGS_INDEX.ExportIndex] == 1:
				Export.button_pressed = true
		param.add_child(pn)
		select_by_id(ParamType,type)
		param_ct += 1
		pn.visible = true	
		
##全局脚本载入到CutscenerGlobal后的事件		
func on_load_global():
	var m_name
	if signal_list.item_count > 0:
		m_name = signal_list.get_item_text(signal_list.selected)
	signal_list.clear()
	signal_list.add_item("Please choose...")
	signal_list.add_separator()
	for method in CutscenerGlobal.CUTSCENE_BUS_METHOD:
		signal_list.add_item(method[0])
	select_by_name(signal_list,m_name)
	
##下拉选择框改变事件
func _on_signal_list_item_selected(index: int) -> void:
	var p_list:Array = []
	var param_text_list_t:Array
	var param2_text_list_t:Array
	for param in props:
		param_text_list_t.append(param.get_child(CONTROL_INDEX.ParamIndex).text)
		param2_text_list_t.append(param.get_child(CONTROL_INDEX.Param2Index).text)
	await clean_all_param()
	for i in CutscenerGlobal.CUTSCENE_BUS_METHOD.size():
		var method = CutscenerGlobal.CUTSCENE_BUS_METHOD[i]
		var method_name = method[0]
		if method_name == signal_list.get_item_text(index):
			var method_return_type:int = method[2]
			is_condition_method = method_return_type > 0
			var method_args = method[1]
			for j in method_args.size():
				var text = ""
				var text2 = ""
				if j < param_text_list_t.size():
					text = param_text_list_t[j]
					text2 = param2_text_list_t[j]
				p_list.append([text,method_args[j]["arg_type"],text2])
			new_param(p_list)
			break
	popdown_menu_visible(false)
	
##根据下拉选项的id选定
func select_by_id(paratype_node,type_id):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_id(a) == type_id:
			paratype_node.select(a)
			break
			
##根据下拉选项的id返回对应的index			
func get_index_by_id(paratype_node,id):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_id(a) == id:
			return a
			
##根据下拉选项的内容选定			
func select_by_name(paratype_node,t_name):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_text(a) == t_name:
			paratype_node.select(a)
			break
			
##删除当前所有的参数项	
func clean_all_param():
	for p in param.get_children():
		p.queue_free()
		await p.tree_exited
	param_ct=1

##节点被选中事件	
func on_selected():
	if param:
		for p in param.get_children():
			p.get_child(CONTROL_INDEX.ExportIndex).visible = true#显示导出按钮
		
##节点取消选中事件			
func on_deselected():
	if param:
		for p in param.get_children():
			p.get_child(CONTROL_INDEX.ExportIndex).visible = false#隐藏导出按钮

