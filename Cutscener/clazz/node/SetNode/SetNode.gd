@tool
extends BaseGraphNode
@onready var param_prototype: HBoxContainer = $main/ParamPrototype
@onready var param: VBoxContainer = $main/VBC/Param
@onready var runner: Node = $runner
@onready var param_type: OptionButton = $main/ParamPrototype/ParamType
@onready var set_type: OptionButton = $main/ParamPrototype/SetType
@onready var prop_list: OptionButton = $main/VBC/Signal/SignalName/PropList
@onready var delete_param: Button = $main/ParamPrototype/DeleteParam
@onready var icon: Button = $main/VBC/Signal/SignalName/Icon

##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	ParamIndex = 0,
	ParamTypeIndex = 1,
	SetTypeIndex = 2,
	Param2Index = 3,
	ExportIndex = 4,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX {
	LabelIndex = 0,
	ParamIndex = 1,
	ParamTypeIndex = 2,
	SetTypeIndex = 3,
	Param2Index = 4,
	DeleteParamIndex = 5,
	ChooseFileIndex = 6,
	ChooseVec2Index = 7,
	ExportIndex = 8,
}
const LABEL_PRESET = "#"
var prop_ct:int = 1:
	set(i):
		props = param.get_children()
		prop_ct=props.size()
		refrsh_index_label()
var props:Array

func ready():
	icon.icon = get_theme_icon("Edit","EditorIcons")
	param_type.clear()
	set_type.clear()
	for type in CutscenerGlobal.VAR_TYPE.values():
		param_type.add_item(CutscenerGlobal.VAR_TYPE_DIC[type][0],type)
		param_type.set_item_disabled(get_index_by_id(param_type,type),true)
	for type in CutscenerGlobal.SET_TYPE.values():
		set_type.add_item(CutscenerGlobal.SET_TYPE_DIC[type][0],type)
		
func init_var():
	node_type=CutscenerGlobal.NODES.SET_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["SetNode",self.title]

func get_save(is_saving_other:bool=false):
	prop_ct=1
	var params:Array
	for i in props.size():
		var pc = props[i].get_children()
		var args = [
			pc[CONTROL_INDEX.ParamIndex].text,#目标参数名
			pc[CONTROL_INDEX.ParamTypeIndex].get_selected_id(),#目标参数类型
			pc[CONTROL_INDEX.SetTypeIndex].get_selected_id(),#目标参数set类型
			pc[CONTROL_INDEX.Param2Index].text,#对比的目标值
			pc[CONTROL_INDEX.ExportIndex].is_export#是否在聚合节点导出
		]
		##[[参数1,参数1类型,参数1目标,参数1是否导出0/1],[参数2,参数2类型,参数2目标,参数2是否导出]]
		params.append(args)
		for p_name in node_save_data.keys():
			if p_name.contains("props") and p_name!="props":
				var prop = node_save_data[p_name][i]
				node_save_data[p_name][i][ARGS_INDEX.ExportIndex] = pc[CONTROL_INDEX.ExportIndex].is_export
	node_save_data["props"] = params
	node_save_data["prop_name"] = prop_list.get_item_text(prop_list.get_selected_id())
	return node_save_data
	
func load_save(combine_node_name:String = "NA",dic_raw:Dictionary = {}):
	await clean_all_param()
	var params:Array
	for i in prop_list.get_item_count():
		if prop_list.get_item_text(i)==node_save_data["prop_name"]:
			prop_list.select(i)
			break
	var props:Array = node_save_data["props"]
	##当存档文件中存在combine_node数据时,转为载入
	if !combine_node_name=="NA" and node_save_data.has(combine_node_name+"_props"):
		props = node_save_data[combine_node_name+"_props"]
		CutscenerGlobal.ACTION_LOG = "[%s]载入聚合node数据覆盖!" %combine_node_name
	new_param(props)
	
func refrsh_index_label():
	for i in props.size():
		props[i].get_children()[0].text = LABEL_PRESET + str(i+1)
	self.size.y=0
	
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
		var SetType = pn.get_node("SetType")
		SetType.clear()
		for type in CutscenerGlobal.VAR_TYPE_DIC[int(p[ARGS_INDEX.ParamTypeIndex])][2]:
			SetType.add_item(CutscenerGlobal.SET_TYPE_DIC[type][0],type)	
		Param.text = p[ARGS_INDEX.ParamIndex]
		Param2.text = p[ARGS_INDEX.Param2Index]
		if p.size()>=5:
			if p[ARGS_INDEX.ExportIndex] == 1:
				Export.button_pressed = true
		var type =  p[ARGS_INDEX.ParamTypeIndex]
		if type==TYPE_VECTOR2:
			ChooseVec2.show()
		elif type==TYPE_OBJECT:
			ChooseFile.show()
		param.add_child(pn)
		pn.get_node("DeleteParam").remove_param.connect(on_remove_param)
		select_by_id(ParamType,p[ARGS_INDEX.ParamTypeIndex])
		select_by_id(SetType,p[ARGS_INDEX.SetTypeIndex])
		prop_ct += 1
		pn.visible = true	
		
func on_load_global():
	var m_name
	if prop_list.item_count > 0:
		m_name = prop_list.get_item_text(prop_list.selected)
	prop_list.clear()
	for prop in CutscenerGlobal.CUTSCENE_BUS_STATE.keys():
		prop_list.add_item(prop)
	select_by_name(prop_list,m_name)
		
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
	prop_ct=1

func _on_add_param_pressed() -> void:
	var prop = prop_list.get_item_text(prop_list.selected)
	new_param([[prop,CutscenerGlobal.CUTSCENE_BUS_STATE[prop],0,""]])
	
func on_remove_param() -> void:
	prop_ct-=1

func on_selected():
	if param:
		for p in param.get_children():
			p.get_child(CONTROL_INDEX.ExportIndex).visible = true
			
func on_deselected():
	if param:
		for p in param.get_children():
			p.get_child(CONTROL_INDEX.ExportIndex).visible = false
