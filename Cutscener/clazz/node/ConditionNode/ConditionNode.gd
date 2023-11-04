@tool
extends BaseGraphNode
@onready var param_prototype: HBoxContainer = $main/ParamPrototype
@onready var param: VBoxContainer = $main/VBC/Param
@onready var runner: Node = $runner
@onready var param_type: OptionButton = $main/ParamPrototype/ParamType
@onready var prop_list: OptionButton = $main/VBC/Signal/SignalName/PropList
@onready var delete_param: Button = $main/ParamPrototype/DeleteParam
@onready var condition_type: OptionButton = $main/ParamPrototype/ConditionType
@onready var condition_link_type: OptionButton = $main/ParamPrototype/ConditionLinkType
@onready var icon: Button = $main/VBC/Signal/SignalName/Icon

const LABEL_PRESET = "#"
##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	ConditionLinkTypeIndex = 0,
	ParamIndex = 1,
	ParamTypeIndex = 2,
	ConditionTypeIndex = 3,
	Param2Index = 4,
	ExportIndex = 5,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX {
	ConditionLinkTypeIndex = 0,
	LabelIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	DeleteParamIndex = 6,
	ChooseFileIndex = 7,
	ChooseVec2Index = 8,
	ExportIndex = 9,
}
##当前参数个数
var prop_ct:int = 1:
	set(i):
		props = param.get_children()
		prop_ct=props.size()
		refrsh_index_label()
##存档数据		
var props:Array

func init_var():
	node_type=CutscenerGlobal.NODES.CONDITION_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["ConditionNode",self.title]
	
func ready():
	icon.icon = get_theme_icon("VcsBranches","EditorIcons")
	param_type.clear()
	for type in CutscenerGlobal.VAR_TYPE.values():
		param_type.add_item(CutscenerGlobal.VAR_TYPE_DIC[type][0],type)
		param_type.set_item_disabled(get_index_by_id(param_type,type),true)
	condition_type.clear()
	for c_type in CutscenerGlobal.CONDITION_TYPE.values():
		condition_type.add_item(CutscenerGlobal.CONDITION_TYPE_DIC[c_type][0],c_type)
	condition_link_type.clear()
	for cl_type in CutscenerGlobal.CONDITION_LINK_TYPE.values():
		condition_link_type.add_item(CutscenerGlobal.CONDITION_LINK_TYPE_DIC[cl_type][0],cl_type)
		
##获取存档数据	
func get_save(is_saving_other:bool=false):
	prop_ct=1
	var params:Array
	for param in props:
		var pc = param.get_children()
		var args = [
			pc[CONTROL_INDEX.ConditionLinkTypeIndex].get_selected_id(),#当前条件的连接条件类型
			pc[CONTROL_INDEX.ParamIndex].text,#变量名
			pc[CONTROL_INDEX.ParamTypeIndex].get_selected_id(),#变量类型
			pc[CONTROL_INDEX.ConditionTypeIndex].get_selected_id(),#条件类型
			pc[CONTROL_INDEX.Param2Index].text,#判断目标值
			pc[CONTROL_INDEX.ExportIndex].is_export#是否导出
			]
		#[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值,是否导出]
		params.append(args)
		pass
	node_save_data["props"] = params
	node_save_data["prop_name"] = prop_list.get_item_text(prop_list.get_selected_id())
	return node_save_data

##载入存档		
func load_save(combine_node_name:String = "NA",dic_raw:Dictionary = {}):
	await clean_all_param()
	var params:Array
	for i in prop_list.get_item_count():
		if prop_list.get_item_text(i)==node_save_data["prop_name"]:
			prop_list.select(i)
			break
	var props:Array = node_save_data["props"]
	if !combine_node_name=="NA" and node_save_data.has(combine_node_name+"_props"):
		props = node_save_data[combine_node_name+"_props"]
		CutscenerGlobal.ACTION_LOG = "[%s]载入聚合node数据覆盖!" %self.name
	new_param(props)
	pass

##更新标签数字		
func refrsh_index_label():
	for i in props.size():
		props[i].get_children()[CONTROL_INDEX.LabelIndex].text = LABEL_PRESET + str(i+1)
	self.size.y=0

##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]	
func new_param(p_list):
	for p in p_list:
		var pn = param_prototype.duplicate()
		var ConditionLinkType = pn.get_node("ConditionLinkType")
		var ConditionType = pn.get_node("ConditionType")
		var Param = pn.get_node("Param")
		var Param2 = pn.get_node("Param2")
		var ChooseVec2 = pn.get_node("ChooseVec2")
		var ChooseFile = pn.get_node("ChooseFile")
		var ParamType = pn.get_node("ParamType")
		Param.text = p[ARGS_INDEX.ParamIndex]
		Param2.text = p[ARGS_INDEX.Param2Index]
		var type =  p[ARGS_INDEX.ParamTypeIndex]
		if type==TYPE_VECTOR2:
			ChooseVec2.show()
		elif type==TYPE_OBJECT:
			ChooseFile.show()
		param.add_child(pn)
		pn.get_node("DeleteParam").remove_param.connect(on_remove_param)
		select_by_id(ParamType,p[ARGS_INDEX.ParamTypeIndex])
		select_by_id(ConditionType,p[ARGS_INDEX.ConditionTypeIndex])
		select_by_id(ConditionLinkType,p[ARGS_INDEX.ConditionLinkTypeIndex])
		prop_ct += 1
		pn.visible = true	
		
##全局脚本载入到CutscenerGlobal后的事件			
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
	
##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]
func _on_add_param_pressed() -> void:
	var prop = prop_list.get_item_text(prop_list.selected)
	new_param([[0,prop,CutscenerGlobal.CUTSCENE_BUS_STATE[prop],0,""]])

##删除参数事件	
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
