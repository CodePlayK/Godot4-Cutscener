@tool
extends BaseGraphNode
##嵌套节点
##
##选中节点后,从右键菜单中选择合并创建,在未选定节点时选择合并则为导入合并节点
##参数原型
@onready var param_prototype: HBoxContainer = $main/ParamPrototype
@onready var param: VBoxContainer = $main/VBC/Param
##对应执行器
@onready var runner: Node = $runner
##参数类型
@onready var param_type: OptionButton = $main/ParamPrototype/ParamType
##下拉选择框
@onready var prop_list: OptionButton = $main/VBC/Signal/SignalName/PropList
##删除改行参数
@onready var delete_param: Button = $main/ParamPrototype/DeleteParam
##打开数据源文件目录
@onready var linked_file: LineEdit = $EditMenu/EditMenu/VBoxContainer2/HBoxContainer/LinkedFile
@onready var icon: Button = %Icon
var data_node_name
var dic_raw
const LABEL_PRESET = "#"

##储存的数据Array每一位的意义
enum ARGS_INDEX {
	LabelIndex = 0,
	ConditionLinkTypeIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	SetTypeIndex = 5,
	Param2Index = 6,
	DataIndex = 7,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX {
	LabelIndex = 0,
	ConditionLinkTypeIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	SetTypeIndex = 5,
	Param2Index = 6,
	DataIndex = 7,
	DeleteParamIndex = 8,
	ChooseFileIndex = 9,
	ChooseVec2Index = 10,
}
##数据存档目录
var save_file_name:String:
	set(path):
		save_file_name = path
		if linked_file:linked_file.text = path
		
##当前参数个数
var prop_ct:int = 1:
	set(i):
		props = param.get_children()
		prop_ct=props.size()
		refrsh_index_label()
##存档数据
var props:Array

func init_var():
	node_type=CutscenerGlobal.NODES.COMBINE_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["CombineNode",self.title]

func ready():
	icon.icon = get_theme_icon("AnimationTrackList","EditorIcons")
	param_type.clear()
	for type in CutscenerGlobal.VAR_TYPE.values():
		param_type.add_item(CutscenerGlobal.VAR_TYPE_DIC[type][0],type)
		param_type.set_item_disabled(get_index_by_id(param_type,type),true)
		
##从存档中载入嵌套节点数据
func on_load_combine_node():
	dic_raw = load_json(save_file_name)##将整个存档文件保存
	var dic = dic_raw["base"]##聚合模板存档文件的基础数据
	node_save_data["save_file_name"] = save_file_name
	node_save_data["data_node_name"] = data_node_name
	self.title = save_file_name.get_file().get_slice(".",0)
	export_props(dic)##从模板中导出参数
	connect_nodes(dic)
	
##将存档中所有param数据最后一位为1的数据导出
##(数据字典,是否为从存档中载入,对应合并节点;是=读存档文件生成param,否=从选中的节点生成,对应打开聚合节点)
func export_props(dic:Dictionary,is_load_save:bool = false):
	for type in CutscenerGlobal.NODE_TYPE.keys():
		type = str(type)
		if !dic.has(type):continue
		for node in dic[type].keys():
			var list_name:String
			if type == "1" and dic[type][node].has("props"):#是signalnode
				list_name = "props"
				if is_load_save and dic[type][node].has(self.name + "_props") :list_name= self.name + "_props"
				for i in dic[type][node][list_name].size():
					var param = dic[type][node][list_name][i]
					if get_is_export(param):
						var arg:Array = [[0,0],[0,0],[param[0],1],[param[1],1],[0,0],[0,0],[param[2],1],[type,node,list_name,i]]
						new_param(arg)
			elif type == "2" and dic[type][node].has("props"):#setnode
				list_name = "props"
				if is_load_save and dic[type][node].has(self.name + "_props") :list_name= self.name + "_props"
				for i in dic[type][node][list_name].size():
					var prop = dic[type][node][list_name][i]
					if get_is_export(prop):
						var arg:Array = [[0,0],[0,0],[prop[0],1],[prop[1],1],[0,0],[prop[2],1],[prop[3],1],[type,node,list_name,i]]
						new_param(arg)				
			elif type == "3" and dic[type][node].has("props"):#conditionnode
				list_name = "props"
				if is_load_save and dic[type][node].has(self.name + "_props") :list_name= self.name + "_props"
				for i in dic[type][node][list_name].size():
					var prop = dic[type][node][list_name][i]
					if get_is_export(prop):
						var arg:Array = [[0,0],[prop[0],1],[prop[1],1],[prop[2],1],[prop[3],1],[0,0],[prop[4],1],[type,node,list_name,i]]
						new_param(arg)				
						
##新建参数条目
func new_param(params):
	var pn = param_prototype.duplicate()
	var label = pn.get_node("Label")
	var Param = pn.get_node("Param")
	var ParamType = pn.get_node("ParamType")
	var Param2 = pn.get_node("Param2")
	var ChooseVec2 = pn.get_node("ChooseVec2")
	var ChooseFile = pn.get_node("ChooseFile")
	var ConditionLinkType = pn.get_node("ConditionLinkType")
	var ConditionType = pn.get_node("ConditionType")
	var SetType = pn.get_node("SetType")
	var Data = pn.get_node("Data")
	Data.text = str(params[ARGS_INDEX.DataIndex])
	if params[ARGS_INDEX.LabelIndex][1]!=0:
		label.text =  str(params[ARGS_INDEX.LabelIndex][0])
		label.visible = true
	if params[ARGS_INDEX.ParamIndex][1]!=0:
		Param.text = str(params[ARGS_INDEX.ParamIndex][0])
		Param.visible = true
	if params[ARGS_INDEX.ParamTypeIndex][1]!=0:
		select_by_id(ParamType,params[ARGS_INDEX.ParamTypeIndex][0])
		ParamType.visible = true
	if params[ARGS_INDEX.Param2Index][1]!=0:
		Param2.text = str(params[ARGS_INDEX.Param2Index][0])
		Param2.visible = true
	if params[ARGS_INDEX.ConditionLinkTypeIndex][1]!=0:
		select_by_id(ConditionLinkType,params[ARGS_INDEX.ConditionLinkTypeIndex][0])
		ConditionLinkType.visible = true
	if params[ARGS_INDEX.ConditionTypeIndex][1]!=0:
		select_by_id(ConditionType,params[ARGS_INDEX.ConditionTypeIndex][0])
		ConditionType.visible = true
	if params[ARGS_INDEX.SetTypeIndex][1]!=0:
		SetType.clear()
		for type in CutscenerGlobal.VAR_TYPE_DIC[int(params[ARGS_INDEX.ParamTypeIndex][0])][2]:
			SetType.add_item(CutscenerGlobal.SET_TYPE_DIC[type][0],type)	
		select_by_id(SetType,params[ARGS_INDEX.SetTypeIndex][0])
		SetType.visible = true
	var type = params[ARGS_INDEX.ParamTypeIndex][0]
	if type==5:
		ChooseVec2.show()
	elif type==24:
		ChooseFile.show()
	param.add_child(pn)
	prop_ct += 1
	pn.visible = true	
		
##从存档文件中判断是否需要导出,要求存档条目的最后一位必须为导出标记
func get_is_export(param:Array):
	if param[param.size()-1] == 1:#检测最后一位是否为1
		return true
		
##连接所有外部node,所需连接的点存于dic["parents"]与dic["childrens"]中
func connect_nodes(dic):
	var editor:GraphEdit = CutscenerGlobal.GRAPH_EDITOR
	var connection_list_with_out_side = dic["connection_list_with_out_side"]
	node_save_data["connection_list_with_out_side"] = connection_list_with_out_side
	if dic.has("parents"):
		var parents = dic["parents"]
		for connection in connection_list_with_out_side:
			var fn = connection["from_node"]
			var tn = connection["to_node"]
			var fp = connection["from_port"]
			var tp = connection["to_port"]
			if parents.has(fn):
				editor.connect_node(fn,fp,self.name,0)
	if dic.has("childrens"):
		var childrens = dic["childrens"]
		for connection in connection_list_with_out_side:
			var fn = connection["from_node"]
			var tn = connection["to_node"]
			var fp = connection["from_port"]
			var tp = connection["to_port"]
			if childrens.has(tn):
				editor.connect_node(self.name,0,tn,tp)
				
##组装存档数据,并且将数据更新到链接的存档文件
##(是否是另存为,是=跳过保存)
func get_save(is_saving_other:bool=false):
	if !is_saving_other:
		combine_node_get_save(self.name)

##创建聚合节点与保存时被调用
##根据当前聚合节点的数据,保存到存档文件中对应的聚合数据
func combine_node_get_save(name:String):
	prop_ct=1
	var params:Array
	for param in props:
		var pc = param.get_children()
		var arg = [
		[pc[CONTROL_INDEX.LabelIndex].text,int(pc[CONTROL_INDEX.LabelIndex].visible)],#[Param参数值,可见]
		[pc[CONTROL_INDEX.ConditionLinkTypeIndex].get_selected_id(),int(pc[CONTROL_INDEX.ConditionLinkTypeIndex].visible)],#[Param参数值,可见]
		[pc[CONTROL_INDEX.ParamIndex].text,int(pc[CONTROL_INDEX.ParamIndex].visible)],#[ParamType参数值,可见]
		[pc[CONTROL_INDEX.ParamTypeIndex].get_selected_id(),int(pc[CONTROL_INDEX.ParamTypeIndex].visible)],#[Param2参数值,可见]
		[pc[CONTROL_INDEX.ConditionTypeIndex].get_selected_id(),int(pc[CONTROL_INDEX.ConditionTypeIndex].visible)],#[链接判断条件or and,可见]
		[pc[CONTROL_INDEX.SetTypeIndex].get_selected_id(),int(pc[CONTROL_INDEX.SetTypeIndex].visible)],#[判断类型==,可见]
		[pc[CONTROL_INDEX.Param2Index].text,int(pc[CONTROL_INDEX.Param2Index].visible)],#[判断类型==,可见]
		CutscenerGlobal.string_2_var(pc[CONTROL_INDEX.DataIndex].text,TYPE_ARRAY)]#[传递data]
		params.append(arg)
	node_save_data["props"] = params
	node_save_data["save_file_name"] = save_file_name
	node_save_data["prop_name"] = prop_list.get_item_text(prop_list.get_selected_id())
	var dic
	if dic_raw.has(data_node_name):#如果存档文件中有聚合数据
		dic = dic_raw[data_node_name]
	else :#如果存档文件中没有聚合数据,则从聚合模板存档文件中读取
		CutscenerGlobal.ACTION_LOG = "当前存档[%s]中未找到聚合数据[%s],转为读取模板[%s]." %[CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"],data_node_name,save_file_name]
		dic_raw[data_node_name] = load_json(save_file_name)["base"]
		dic = dic_raw[data_node_name]
	node_save_data["data_node_name"] = data_node_name
	var my_props#要保存的数据
	var last_type#上一个保存的节点类型
	for param in params:
		var p_data:Array = param[ARGS_INDEX.DataIndex]
		var Param:String = param[ARGS_INDEX.ParamIndex][0]
		var Param2:String = param[ARGS_INDEX.Param2Index][0]
		var LinkType = param[ARGS_INDEX.ConditionLinkTypeIndex][0]
		var ConditionType = param[ARGS_INDEX.ConditionTypeIndex][0]
		var SetType = param[ARGS_INDEX.SetTypeIndex][0]
		var type = str(p_data[0])
		var node_name = p_data[1]
		var list_name = p_data[2]
		var index = p_data[3]
		var my_list_name= name + "_props"#私有存档名
		if type != last_type:#遍历的节点类型改变时,重新获取原型
			if dic[type][node_name].has(list_name):
				my_props = dic[type][node_name][list_name].duplicate(true)
		if !dic.has(type):
			CutscenerGlobal.ACTION_LOG = "引用的原数据没有对应node类型,跳过![%s]" %str(param)
			continue
		if !dic[type].has(node_name):
			CutscenerGlobal.ACTION_LOG = "引用的原数据没有对应node,跳过![%s]" %str(param)
			continue
		if !dic[type][node_name].has(list_name):
			CutscenerGlobal.ACTION_LOG = "引用的原数据没有对应数据list,跳过![%s]" %str(param)
			continue
		if !dic[type][node_name][list_name].size()>index:
			CutscenerGlobal.ACTION_LOG = "引用的原数据没有对应index,跳过![%s]" %str(param)
			continue
		match int(type):
			1:#signalNode类型
				var my_prop = dic["1"][node_name][list_name][index].duplicate(true)
				my_prop[0] = Param
				my_prop[2] = Param2
				my_props[index] = my_prop
			2:#setNode类型
				var my_prop = dic["2"][node_name][list_name][index].duplicate(true)
				my_prop[2] = SetType
				my_prop[3] = Param2
				my_props[index] = my_prop
			3:#conditionNode类型
				var my_prop = dic["3"][node_name][list_name][index].duplicate(true)
				my_prop[0] = LinkType
				my_prop[1] = Param
				my_prop[3] = ConditionType
				my_prop[4] = Param2
				my_props[index] = my_prop
		last_type = type
		if !dic[type][node_name].has(my_list_name):
			dic[type][node_name][my_list_name] = []
		dic[type][node_name][my_list_name]=my_props	
	CutscenerGlobal.COMBINE_DATAS[data_node_name] = dic#将自己的聚合数据保存到缓存
	props.clear()
	return node_save_data
	
##从链接存档中载入数据,会根据存档内容更新导出的条目,而具体数据则以父存档为准
func load_save(combine_node_name:String = "NA",dic_raw1:Dictionary = {}):
	await clean_all_param()
	dic_raw = dic_raw1
	var dic
	save_file_name = node_save_data["save_file_name"]#从存档数据中获取存档文件地址
	if node_save_data.has("data_node_name"):#从存档数据中获取聚合数据名
		data_node_name = node_save_data["data_node_name"]
	if dic_raw.has(data_node_name):
		dic = dic_raw[data_node_name]
		export_props(dic,true)#从聚合数据导出参数
		
##刷新序号标签	
func refrsh_index_label():
	for i in props.size():
		props[i].get_children()[0].text = LABEL_PRESET + str(i+1)
	self.size.y=0
	
##全局变量载入到CutscenerGlobal后事件
func on_load_global():
	prop_list.clear()
	for prop in CutscenerGlobal.CUTSCENE_BUS_STATE.keys():
		prop_list.add_item(prop)
	pass
		
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
	
##读取本地json文件
func load_json(file_name):
	if !FileAccess.file_exists(file_name):
		CutscenerGlobal.ACTION_LOG = "[%s][%s]文件不存在!" %[self.name,file_name]
		return
	var file = FileAccess.open(file_name, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	var data_received = json.data as Dictionary
	return data_received
	
##保存到本地json文件	
func save_json(file_name:String,file_data):
	DirAccess.make_dir_recursive_absolute(file_name.get_base_dir())
	DirAccess.open(file_name.get_base_dir())
	DirAccess.remove_absolute(file_name)
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_line(JSON.stringify(file_data,"\t"))
	
##删除请求事件	,删除前暂时将存档文件名储存,以用于重新载入
func on_delete(is_delete:bool = true):
	if is_delete:
		if !CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME.has(data_node_name):
			CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME[data_node_name] = []
		CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME[data_node_name].append(self.name)

##复制节点事件,将自身数据链接到原节点上
func duplicate_node(node):
	save_file_name = node.save_file_name
	data_node_name = node.data_node_name
	dic_raw = node.dic_raw
	node_save_data["save_file_name"] =node.save_file_name
	node_save_data["data_node_name"] =node.data_node_name
	self.title = node.title
	
##显示链接数据
func show_all_link_data(flag):
	for p in param.get_children():
		p.get_child(CONTROL_INDEX.DataIndex).visible = flag
		
##另存为事件,根据新节点名在连接存档中生成新条目
func save_as(new_name:String):
	combine_node_get_save(new_name)
