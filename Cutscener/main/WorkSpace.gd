@tool
extends HSplitContainer
##主界面
##
##主要运行代码中心
@onready var popup_menu: PopupMenu = $GraphEdit/PopupMenu
var cursor_pos = Vector2.ZERO
@onready var graph_edit: GraphEdit = $GraphEdit
@onready var prototype: Control = $GraphEdit/Prototype
@onready var clipboard: Control = $GraphEdit/Clipboard
@onready var file_dialog: FileDialog = $"../../FileDialog"
@onready var file_label: Label = $"../HBoxContainer/FileLabel"
@onready var action_panel: Panel = $"../HBoxContainer/ActionPanel"
@onready var action_label: Label = $"../HBoxContainer/ActionPanel/ActionLabel"
@onready var node_file_dialog: FileDialog = $"../../NodeFileDialog"
@onready var popup_dialog: ConfirmationDialog = $"../../PopupDialog"
@onready var project_choose: OptionButton = $"../MenuBar/run_config/project_choose"
@onready var combine_node_file_dialog: FileDialog = $"../../CombineNodeFileDialog"
@onready var cutscener_runner: = $"../../CutscenerRunner"
@onready var setting_dialog: AcceptDialog = $"../../SettingDialog"
@onready var file_history: ItemList = $SideBar/FileHistory
@onready var side_bar: VBoxContainer = $SideBar
@onready var sidebar: Button = $"../MenuBar/sidebar"

func _init() -> void:
	CutscenerGlobal.load_all_method_state_from_global.connect(on_load_all_method_state_from_global)
	
func _ready() -> void:
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	CutscenerGlobal.running_node_changed.connect(on_running_node_changed)#当前节点变化
	CutscenerGlobal.log_change.connect(on_log_change)#log变化
	CutscenerGlobal.clear_node_connection.connect(clear_node_connection)#清除节点所有连接线
	CutscenerGlobal.discombine_node.connect(on_discombine_node)#聚合节点分解
	CutscenerGlobal.file_history_changed.connect(on_file_history_changed)#文件历史
	CutscenerGlobal.WORK_SPACE = self#注册到CutscenerGlobal
	
func on_load_all_method_state_from_global():
	##载入指定的全局脚本方法数据
	if CutscenerGlobal.METHOD_BUSES and !CutscenerGlobal.METHOD_BUSES.is_empty():
		CutscenerGlobal.CUTSCENE_BUS_METHOD=[]
		for bus in CutscenerGlobal.METHOD_BUSES:
			#CutscenerGlobal.ACTION_LOG = "载入METHOD_BUS [%s]" %bus
			for method in get_tree().get_root().get_node(bus).get_method_list():
				if method.flags == 1 and method.id ==0 and method.name !="free":
					var args:Array = method["args"]
					var args_real:Array= []
					for arg in args:
						args_real.append({"arg_name":arg["name"],"arg_type":arg["type"]})
					CutscenerGlobal.CUTSCENE_BUS_METHOD.append([bus+"."+method["name"],args_real,method["return"]["type"]])
	##载入指定的全局脚本变量数据
	if CutscenerGlobal.STATE_BUSES and !CutscenerGlobal.STATE_BUSES.is_empty():
		CutscenerGlobal.CUTSCENE_BUS_STATE = {}
		for bus in CutscenerGlobal.STATE_BUSES:
			#CutscenerGlobal.ACTION_LOG = "载入STATE_BUS [%s]" %bus
			var prop_list:Array =get_tree().get_root().get_node(bus).get_property_list()
			for i in prop_list.size():
				if i > 18:
					var prop = prop_list[i]
					CutscenerGlobal.CUTSCENE_BUS_STATE[bus+"."+prop["name"]]=prop["type"]
	CutscenerGlobal.load_global.emit()##载入完毕后通知节点配置数据
	
##右键菜单弹出事件	
func _on_graph_edit_popup_request(position: Vector2) -> void:
	var selected_nodes:Array = []
	for node_name in CutscenerGlobal.NODE_INST.keys():
		if CutscenerGlobal.NODE_INST[node_name].selected : selected_nodes.append(node_name)
	if !selected_nodes.is_empty():
		CutscenerGlobal.NODE_INST_SELECTED.clear()
	CutscenerGlobal.NODE_INST_SELECTED = selected_nodes
	if !CutscenerGlobal.NODE_INST_SELECTED.size()>1:
		popup_menu.set_item_text(popup_menu.get_item_index(101),"导入聚合节点文件 / Load combine save...")
	else :
		popup_menu.set_item_text(popup_menu.get_item_index(101),"合并选中节点 / Combine selected nodes...")
	var pop_pos = get_global_mouse_position()
	popup_menu.popup(Rect2(pop_pos.x, pop_pos.y, popup_menu.size.x, popup_menu.size.y))
	cursor_pos = (pop_pos + graph_edit.scroll_offset- graph_edit.get_screen_position()) / graph_edit.zoom#鼠标位置
	
##右键菜单点击事件,根据id来创建节点
func _on_popup_menu_id_pressed(id: int) -> void:
	var pro_nodes = prototype.get_children()#获取所有节点原型
	for pro_node in prototype.get_children():
		if pro_node.node_type!=id:
			continue
		if id < 100:#小于100为创建节点
			var node = duplicate_prototype_to_editor(pro_node)
			node.naming_node_and_add_2_global(true)
			node.position_offset = cursor_pos#需要额外减去当前的屏幕位置
		if id == 101:#创建聚合节点
			if CutscenerGlobal.NODE_INST_SELECTED.size()>1:
				var has_start_node:bool = false
				for node_inst in CutscenerGlobal.NODE_INST_SELECTED:
					if CutscenerGlobal.NODE_INST[node_inst].node_type == 101:
						CutscenerGlobal.popup("合并的节点中不能包含聚合节点! \nNo CombineNode while combining!","警告")
						return
					elif CutscenerGlobal.NODE_INST[node_inst].node_type == 0:
						has_start_node = true
				if !has_start_node:
						CutscenerGlobal.popup("合并的节点中未新建起点节点! \nStartNode not find!","警告")
						return
				#当前如果选中了1个以上的节点,则创建合并节点
				combine_node_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
				combine_node_file_dialog.show()
				await combine_node_file_dialog.finished
				if combine_node_file_dialog.ok:
					var node= duplicate_prototype_to_editor(pro_node)
					node.naming_node_and_add_2_global(true)
					node.position_offset = cursor_pos#需要额外减去当前的屏幕位置
					combine_nodes(node)
			else :#否则从存档中载入聚合节点
				combine_node_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
				combine_node_file_dialog.show()
				await combine_node_file_dialog.finished
				if combine_node_file_dialog.ok:
					var node= duplicate_prototype_to_editor(pro_node)
					node.naming_node_and_add_2_global(true)
					node.position_offset = cursor_pos#需要额外减去当前的屏幕位置
					load_combine_nodes(node)
					
##载入聚合节点存档					
func load_combine_nodes(combine_node):
	var save_file_name = combine_node_file_dialog.current_path
	combine_node.save_file_name = save_file_name##模板文件地址
	combine_node.data_node_name = combine_node.name##链接的聚合节点存档数据名
	combine_node.on_load_combine_node()
	save_graph(CutscenerGlobal.NODE_INST.keys(),CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
	
##创建聚合节点:
##1.将选中的节点保存为单独的.cnd文件		
##2.新建的聚合节点会将聚合数据保存在缓存中(CutscenerGlobal.COMBINE_DATAS)	
func combine_nodes(combine_node):
	var save_file_name = combine_node_file_dialog.current_path
	save_graph(CutscenerGlobal.NODE_INST_SELECTED,save_file_name)#从选中的节点中创建聚合模板
	combine_node.save_file_name = save_file_name
	combine_node.data_node_name = combine_node.name
	combine_node.on_load_combine_node()#调用node载入事件
	for sn in CutscenerGlobal.NODE_INST_SELECTED:
		clear_node_connection(sn)
		CutscenerGlobal.NODE_INST[sn].delete_self(false)
	save_graph(CutscenerGlobal.NODE_INST.keys(),CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])	

##解散聚合节点		
func on_discombine_node(combine_node):
	CutscenerGlobal.ACTION_LOG = "开始分解聚合节点[%s]" %combine_node.name
	clear_node_connection(combine_node.name)
	#从存档文件中的指定聚合数据中读取
	load_greph(false,CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"],combine_node.name,combine_node.data_node_name)
	if combine_node.node_save_data.has("connection_list_with_out_side"):
		for connection in combine_node.node_save_data["connection_list_with_out_side"]:#根据存档中的外部节点数据连线
			graph_edit.connect_node(str(connection["from_node"]),int(connection["from_port"]),str(connection["to_node"]),int(connection["to_port"]))
	combine_node.delete_self(true)#分解完毕后通知聚合节点删除,但不会删除链接的源存档文件
	
##将原型node复制到主视图下		
func duplicate_prototype_to_editor(pro_node:Node):
	var node = pro_node.duplicate()
	graph_edit.add_child(node)
	node.set_visible(true)
	return node
	
##连接node
func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	CutscenerGlobal.ACTION_LOG = "连接node:[%s].%s->[%s].%s" %[from_node,from_port,to_node,to_port]
	var ct = get_node_children_max_index(from_node)
	CutscenerGlobal.NODE_INST[to_node].edit_menu.base_index = ct + 1
	graph_edit.connect_node(from_node,from_port,to_node,to_port)

##将多个节点保存到指定文件(要保存的所有节点,要存档的文件名,是否为另存为)
func save_graph(node_name_list:Array,file_name:String = CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"],is_saving_other:bool = false):
	##更新config文件中的当前存档文件位置
	var dic_fin:Dictionary = {}
	var dic:Dictionary = {}
	CutscenerGlobal.ACTION_LOG = "保存视图:[%s]" %CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]
	var connection_list_t = graph_edit.get_connection_list()
	var connection_list:Array
	var connection_list_with_out_side:Array
	for i in connection_list_t.size():
		if node_name_list.has(connection_list_t[i]["from_node"]) and node_name_list.has(connection_list_t[i]["to_node"]):
			connection_list.append(connection_list_t[i])
		if node_name_list.has(connection_list_t[i]["from_node"]) or node_name_list.has(connection_list_t[i]["to_node"]):
			connection_list_with_out_side.append(connection_list_t[i])
	dic["connection_list"] = connection_list#保存要保存的节点相关的连接配置
	dic["graph_positon"] = [graph_edit.scroll_offset.x,graph_edit.scroll_offset.y,graph_edit.zoom]#保存主视图位置
	dic["connection_list_with_out_side"] = connection_list_with_out_side#保存主视图中所有节点连接配置
	for node_name in node_name_list:
		##获取当前node_list中连接到外部的所有父节点和子节点
		var parents = get_all_parent_node(node_name)
		for parent in parents:
			if !node_name_list.has(parent):
				if !dic.has("parents"):
					dic["parents"]=[parent]
				if !dic["parents"].has(parent):dic["parents"].append(parent)
		var childrens = get_all_children_node(node_name)
		for children in childrens:
			if !node_name_list.has(children):
				if !dic.has("childrens"):
					dic["childrens"]=[children]
				if !dic["childrens"].has(children):dic["childrens"].append(children)
		var node = CutscenerGlobal.NODE_INST[node_name]#根据节点名获取实例
		if node.has_meta("node_type") :
			var node_type = node.get_meta("node_type")
			if !dic.has(node_type):
				dic[node_type]={}
			dic[node_type][node.name]=node.get_save_data(is_saving_other)#获取节点组装的数据
			if node_type == 101:#如果是聚合节点则额外记录外部连接节点
				dic[node_type][node.name]["connection_list_with_out_side"] = connection_list_with_out_side
			if !dic.has("nodes_type"):
				dic["nodes_type"]={}
			dic["nodes_type"][node.name]=node_type#节点的类型单独保存在nodes_type中
	get_runner_data(dic)
	if is_saving_other:#另存为时
		var str_dic = JSON.stringify(dic)#存档字典转为json字符
		for node_map in CutscenerGlobal.CONNECTION_LIST_MAP:#从CONNECTION_LIST_MAP中获取另存为节点新名与旧名的映射
			str_dic.replace(node_map[0],node_map[1])#将所有旧名替换为新名
		dic = CutscenerGlobal.json_2_var(str_dic)
	dic_fin["base"] = dic
	dic_fin.merge(CutscenerGlobal.COMBINE_DATAS)#将聚合数据缓存的数据保存
	if !is_saving_other:#非另存为时,删除所有已解散或删除的聚合节点的数据
		remove_combine_node_props(dic_fin)
	CutscenerGlobal.COMBINE_DATAS.clear()
	save_json(file_name,dic_fin)

##根据CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME清除已删除的聚合节点的所有数据props	
func remove_combine_node_props(dic_raw:Dictionary):
	for combine_data in CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME.keys():
		if !dic_raw.has(combine_data):continue
		for combine_node_name in CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME[combine_data]:
			for node_name in dic_raw[combine_data]["nodes_type"].keys():
				var node_type = dic_raw[combine_data]["nodes_type"][node_name]
				dic_raw[combine_data][str(node_type)][node_name].erase(combine_node_name + "_props")
	CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME.clear()
	return dic_raw		
##从存档数据中获取Runner所需的数据
##格式:{from_node1:[to_node1,parent_index1,from_prot1],from_node2:[to_node2,parent_index2,from_prot2]}
##{父节点:[子节点1,在父节点中的index顺序,连接到的父节点槽id]}
func get_runner_data(dic):
	var connection_list = dic["connection_list"]
	var run_data:Dictionary
	for cfr in connection_list:
		var cf = cfr["from_node"]
		var ct = cfr["to_node"]
		var cfp = cfr["from_port"]
		var ctp = cfr["to_port"]
		if run_data.has(cf):
			run_data[cf].append([ct,get_node_index(ct,dic),cfp])
		else :
			run_data[cf]=[[ct,get_node_index(ct,dic),cfp]]
	dic["run_data"]=run_data	
	return dic
	
##获取一个父节点
func get_parent_node(node_name):
	var connection_list = graph_edit.get_connection_list()
	for cfr in connection_list:
		var cf = cfr["from_node"]
		var ct = cfr["to_node"]	
		if ct == node_name : 
			return cf
			
##获取所有父节点
func get_all_parent_node(node_name):
	var parent_list:Array
	var connection_list = graph_edit.get_connection_list()
	for cfr in connection_list:
		var cf = cfr["from_node"]
		var ct = cfr["to_node"]	
		if ct == node_name :
			if !parent_list.has(cf):parent_list.append(cf)
	return parent_list
	
##获取节点的所有子节点
func get_all_children_node(node_name):
	var children_list:Array
	var connection_list = graph_edit.get_connection_list()
	for cfr in connection_list:
		var cf = cfr["from_node"]
		var ct = cfr["to_node"]	
		if cf == node_name :
			if !children_list.has(ct):children_list.append(ct)
	return children_list
	
##获取节点的所有子节点的最大index		
func get_node_children_max_index(node_name):
	var connection_list = graph_edit.get_connection_list()
	var children_index_max = 0
	for cfr in connection_list:
		var cf = cfr["from_node"]
		var ct = cfr["to_node"]
		var index = CutscenerGlobal.NODE_INST[ct].edit_menu.base_index
		if cf == node_name : children_index_max = max(children_index_max,index)
	return	children_index_max

##从存档数据中获取节点在父节点的index
func get_node_index(node_name,dic):
	if !dic["nodes_type"].has(node_name):return 0
	var node_type = dic["nodes_type"][node_name]
	return	dic[node_type][node_name]["index_by_parent"]
		
##从存档中载入主视图(是否清空主视图,文件名,聚合节点名,聚合数据名)	
func load_greph(is_clean_editor:bool = true,file_name:String = CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"],combine_name:String = "NA",data_node_name:String = "NA"):
	CutscenerGlobal.ACTION_LOG = "载入视图:[%s]" %file_name
	var dic_raw = load_json(file_name)##文件数据
	var dic 
	if is_clean_editor:#清空编辑器则代表为正常载入
		dic = dic_raw["base"]#基础数据
		add_to_file_history(file_name)
		CutscenerGlobal.FILE_SYS_DIC["curren_save_name"] = file_name.get_file()
		CutscenerGlobal.FILE_SYS_DIC["curren_save_path"] = file_name.get_base_dir()
		CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"] = file_name
		clean_editor()
		if dic.has("graph_positon"):
			graph_edit.scroll_offset.x = dic["graph_positon"][0]
			graph_edit.scroll_offset.y = dic["graph_positon"][1]
			graph_edit.zoom = dic["graph_positon"][2]
	else :#不清空则代表是载入聚合存档
		dic = dic_raw[data_node_name]#以聚合数据名从文件中获取聚合数据
		#for node in dic["nodes_type"].keys():
			#var node_type:String = str(dic["nodes_type"][node])
			#for k:String in dic[node_type][node].keys():
				#if k.contains("_props"):dic[node_type][node].erase(k)
	for type in CutscenerGlobal.NODES.values():
		load_by_type(type,dic,combine_name,dic_raw)
	
##清空主视图		
func clean_editor():
	var current_nodes = CutscenerGlobal.NODE_INST
	CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME.clear()##清空分解后聚合节点缓存
	graph_edit.clear_connections()##清空连接
	for cn in current_nodes.keys():##调用节点缓存中的所有节点的释放方法
		if cn!="NA" and current_nodes[cn] and current_nodes[cn].has_method("delete_self"):
			current_nodes[cn].delete_self(false)
		
##根据node类型载入node	(类型,数据,聚合节点名,文件源数据)
func load_by_type(type,dic,combine_name:String = "NA",dic_raw={}):
	if !dic.has(str(type)):return
	var nodes = dic[str(type)]
	for new_node in nodes.keys():
		for pro_node in prototype.get_children():
			if pro_node.node_type==type:
				var node = duplicate_prototype_to_editor(pro_node)
				node.name = new_node
				node.naming_node_and_add_2_global(false)#将节点添加入实例缓存,不需要生成新名
				node.load_save_data(nodes[new_node],combine_name,dic_raw)#节点载入数据
				break
	var connection_list = dic["connection_list"]
	for connection in connection_list:
		graph_edit.connect_node(connection["from_node"],connection["from_port"],connection["to_node"],connection["to_port"])	
	
##载入按钮事件	
func _on_load_2_pressed() -> void:
	if !CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"] == "NA":
		load_greph(true,CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
	else:
		CutscenerGlobal.popup("当前未打开任何存档! \nNo save opened!","未选定存档")
		
##保存按钮事件
func _on_save_button_down() -> void:
	if CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"] == "NA":
		_on_save_other_pressed()
	else:
		save_graph(CutscenerGlobal.NODE_INST.keys(),CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
		
##保存到本地json文件	
func save_json(file_name:String,file_data):
	DirAccess.make_dir_recursive_absolute(file_name.get_base_dir())#
	DirAccess.open(file_name.get_base_dir())
	DirAccess.remove_absolute(file_name)#首先删除文件
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_line(JSON.stringify(file_data,"\t"))
	save_config_file()
	
##更新配置文件	
func save_config_file():
	CutscenerGlobal.CONFIG_DATA_DIC["save_file_config"] = CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]
	DirAccess.remove_absolute(CutscenerGlobal.CONFIG_DATA_FILE_PATH)#删除原配置文件
	DirAccess.make_dir_absolute(CutscenerGlobal.CONFIG_DATA_FILE_PATH.get_base_dir())#确保文件目录存在
	var config = FileAccess.open(CutscenerGlobal.CONFIG_DATA_FILE_PATH, FileAccess.WRITE)
	config.store_line(JSON.stringify(CutscenerGlobal.CONFIG_DATA_DIC,"\t"))
		
##读取本地json文件
func load_json(file_name):
	#CutscenerGlobal.ACTION_LOG = "打开文件[%s]" %file_name
	if !FileAccess.file_exists(file_name):
		CutscenerGlobal.ACTION_LOG = "[%s][%s]文件不存在!" %[self.name,file_name]	
	var file = FileAccess.open(file_name, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	var data_received = json.data as Dictionary
	return data_received

##点击节点槽以删除连线事件
##必须启用[member GraphEdit.right_disconnects]
func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node,from_port,to_node,to_port)
	
##运行按钮事件
func _on_run_pressed() -> void:
	if check_before_run():
		##运行前保存
		save_graph(CutscenerGlobal.NODE_INST.keys(),CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
		cutscener_runner.run(cutscener_runner.cutscener_name)
	else :
		CutscenerGlobal.ACTION_LOG = "运行前检查失败!"

##TODO 为原型node添加自定义检测接口
##运行前检查
func check_before_run() -> bool:
	if CutscenerGlobal.NODE_INST.size()== 0:
		CutscenerGlobal.ACTION_LOG = "当前没有视图节点!!"
		return false
	var start_node_ct=0
	for node in CutscenerGlobal.NODE_INST.keys():
		if !node.begins_with("NA") and  CutscenerGlobal.NODE_INST[node].node_type == CutscenerGlobal.NODES.START_NODE:
			start_node_ct+=1
	if start_node_ct!=1:
		CutscenerGlobal.ACTION_LOG = "起始节点不唯一!!"
		return false
	return true
	
##region 编辑器复制粘贴删除操作
##复制事件
func _on_graph_edit_copy_nodes_request() -> void:
	var new_node_list:Array
	for node_name in CutscenerGlobal.NODE_INST.keys():
		if null!=CutscenerGlobal.NODE_INST[node_name] and CutscenerGlobal.NODE_INST[node_name].is_selected():
			var base_node = CutscenerGlobal.NODE_INST[node_name]
			var new_node = base_node.duplicate(8)#使用实例化进行复制
			new_node.duplicate_data["connection_list"] = graph_edit.get_connection_list()
			new_node.duplicate_data["base_node_name"] = base_node.name
			var max_index = get_node_children_max_index(get_parent_node(base_node.name))
			new_node.duplicate_data["base_index"] = max_index + 1
			new_node.duplicate_node(base_node)
			new_node.selected = false
			new_node.position_offset+=Vector2(15,15)#让复制的节点与原位置偏移一定距离
			new_node.naming_node_and_add_2_global(true)
			new_node_list.append(new_node)
	if !new_node_list.is_empty():
		for node in clipboard.get_children():#先清空剪贴板
			clipboard.remove_child(node)
			node.delete_self(false)
		for new_node in new_node_list:#添加到剪贴板
			clipboard.add_child(new_node)
			
##粘贴事件
func _on_graph_edit_paste_nodes_request() -> void:
	for node_name in CutscenerGlobal.NODE_INST.keys():
		if node_name!="NA":
			CutscenerGlobal.NODE_INST[node_name].set_selected(false)
	for node in clipboard.get_children():
		node.reparent(graph_edit)
		var base_node_name = node.duplicate_data["base_node_name"]
		for connection_dic in node.duplicate_data["connection_list"]:
			if connection_dic["from_node"]==base_node_name:#不需要连接到原子节点
				pass
			elif connection_dic["to_node"]==base_node_name:#连接到原父节点
				graph_edit.connect_node(connection_dic["from_node"],connection_dic["from_port"],node.name,connection_dic["to_port"])	
		node.edit_menu.base_index = node.duplicate_data["base_index"]#复制原节点的运行顺序
		node.set_selected(true)
		
##删除事件
func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		if CutscenerGlobal.NODE_INST.has(node_name):
			CutscenerGlobal.NODE_INST[node_name].delete_self(true)
		
	
##清除该node的所有连接
func clear_node_connection(node_name):
	var connection_list = graph_edit.get_connection_list()
	for connection_dic in connection_list:
		if connection_dic["from_node"]==node_name:
			graph_edit.disconnect_node(node_name,connection_dic["from_port"],connection_dic["to_node"],connection_dic["to_port"])
		elif connection_dic["to_node"]==node_name:
			graph_edit.disconnect_node(connection_dic["from_node"],connection_dic["from_port"],node_name,connection_dic["to_port"])	
##endregion
##region 文件相关
##打开按钮事件
func _on_open_pressed() -> void:
	file_dialog.current_dir = CutscenerGlobal.FILE_SYS_DIC["current_save_path"]
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.show()
	
##文件对话框选择后事件,包含保存与读取,另存为
func _on_file_dialog_file_selected(path: String) -> void:
	add_to_file_history(path)
	CutscenerGlobal.FILE_SYS_DIC["curren_save_name"]=path.get_file()
	CutscenerGlobal.FILE_SYS_DIC["current_save_path"]=path.get_base_dir()
	CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]=path
	match file_dialog.file_mode:
		FileDialog.FILE_MODE_OPEN_FILE:#打开
			load_greph(true,CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
		FileDialog.FILE_MODE_SAVE_FILE:#保存
			CutscenerGlobal.DELETE_COMBINE_NODE_SAVE_FILE_NAME.clear()#清空分解后聚合节点缓存
			for node_name in CutscenerGlobal.NODE_INST.keys():
				CutscenerGlobal.NODE_INST[node_name].on_save_other()#调用所有节点的另存为事件,获得一个新名
			save_graph(CutscenerGlobal.NODE_INST.keys(),CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"],true)
			CutscenerGlobal.CONNECTION_LIST_MAP.clear()
			load_greph(true,CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"])
	on_file_sys_change()
	
##文件系统变化事件
func on_file_sys_change():
	file_label.text = "当前打开文件: %s" %CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]
	
##另存为事件
func _on_save_other_pressed() -> void:
	file_dialog.current_dir = CutscenerGlobal.FILE_SYS_DIC["current_save_path"]
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE	
	file_dialog.show()
	
##新建事件	
func _on_new_pressed() -> void:
	clean_editor()
	CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"] = "NA"
	on_file_sys_change()
	
##endregion

##region UI相关

##log改变事件
func on_log_change(log):
	file_label.text = "当前打开文件: %s" %CutscenerGlobal.FILE_SYS_DIC["current_save_file_path"]
	action_label.text = CutscenerGlobal.ACTION_LOG

##日志展开
func _on_panel_mouse_entered() -> void:
	action_panel.clip_contents = false
	
##日志展开关闭
func _on_action_panel_mouse_exited() -> void:
	action_panel.clip_contents = true

##整理节点
func _on_rearrange_pressed() -> void:
	graph_edit.arrange_nodes()

##当前运行节点变化
func on_running_node_changed(node_name:String) -> void:
	if graph_edit and graph_edit.has_node(node_name):
		graph_edit.get_node(node_name).set_selected(false)
		await get_tree().create_timer(.1).timeout
		graph_edit.get_node(node_name).set_selected(true)
##endregion

##运行游戏
func _on_run_project_pressed() -> void:
	CutscenerGlobal.CONFIG_DATA_DIC["run_type"] = project_choose.selected
	save_config_file()
	EditorInterface.play_main_scene()

func _on_project_choose_item_selected(index: int) -> void:
	CutscenerGlobal.CONFIG_DATA_DIC["run_type"] = index
	save_config_file()
##设置
func _on_setting_pressed() -> void:
	CutscenerGlobal.refresh_setting_autoload_config.emit()
	setting_dialog.show()
##region FileHistory

func on_file_history_changed() -> void:
	file_history.clear()
	for file_name:String in CutscenerGlobal.FILE_HISTORY:
		var index = file_history.add_item(file_name.get_file())
		file_history.set_item_tooltip(index,file_name)

func _on_sidebar_toggled(toggled_on: bool) -> void:
	if toggled_on:
		sidebar.icon = get_theme_icon("Back","EditorIcons")
	else:
		sidebar.icon = get_theme_icon("Forward","EditorIcons")
	side_bar.visible = toggled_on

func _on_file_history_item_activated(index: int) -> void:
	var file = file_history.get_item_tooltip(index)
	if FileAccess.file_exists(file):
		load_greph(true,file)

func add_to_file_history(path):
	if !CutscenerGlobal.FILE_SYS_DIC["file_history"]:
		CutscenerGlobal.FILE_SYS_DIC["file_history"] = []
	if CutscenerGlobal.FILE_SYS_DIC["file_history"].has(path):
		CutscenerGlobal.FILE_SYS_DIC["file_history"].erase(path)
	CutscenerGlobal.FILE_SYS_DIC["file_history"].push_front(path)
	CutscenerGlobal.FILE_HISTORY = CutscenerGlobal.FILE_SYS_DIC["file_history"]
##endregion


func _on_save_pressed() -> void:
	_on_save_button_down()
