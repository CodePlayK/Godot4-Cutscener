@tool
extends Node
##运行节点改变
signal running_node_changed(node_name:String)
##节点删除
signal node_delete(node_name:String)
##日志更新
signal log_change(log:String)
##清除节点所有连线
signal clear_node_connection
##Cutscener运行通知
signal cutscener_started
##Cutscener运行通知
signal cutscener_ended
##聚合节点运行结束
signal run_combine_finished(node_name)
##聚合节点分解
signal discombine_node(node_name)
##载入全局脚本
signal load_global
##过场执行器通知运行
signal cutscener_run(cutscener_name)
##载入指定全局脚本通知
signal load_all_method_state_from_global
##刷新设置中的autoload配置列表
signal refresh_setting_autoload_config
##文件历史刷新
signal file_history_changed
##文本框编辑事件
signal param_modify
##文本框选中
signal param_focus_enter
##文本框离开
signal param_focus_exit
##当前正在运行的节点名
var current_combine_node_name="NA"
##region Node实例基础配置
##生成节点名(节点名,节点的系统object id)
func get_nid(node_name,obj_id):
	var iname = str(node_name).get_slice("_",0)
	return iname+ "_" + str(obj_id)
##真节点槽的颜色
const slot_true_color:Color = Color("1dff92dd")
##假节点槽的颜色
const slot_false_color:Color = Color("ff4a50dd")
##默认节点槽的颜色
const slot_default_color:Color = Color("ffffffe2")
const protect_node_theme:Resource = preload("res://addons/Cutscener/resource/protect_node_theme.tres")
const protect_node_theme_selected:Resource = preload("res://addons/Cutscener/resource/protect_node_theme_selected.tres")
##节点类型字典
##{类型:实例,名称}
var NODE_TYPE:Dictionary={
	NODES.START_NODE:[],
	NODES.SIGNAL_NODE:[],
	NODES.SET_NODE:[],
	NODES.CONDITION_NODE:[],
	NODES.END_NODE:[],
	NODES.COMBINE_NODE:[],
}
##节点类型
enum NODES{
	START_NODE = 0,#起始节点
	SIGNAL_NODE = 1,#信号节点
	SET_NODE = 2,#set节点
	CONDITION_NODE = 3,#条件节点
	END_NODE = 4,#结束节点
	COMBINE_NODE = 101,#聚合节点
}
##另存为时的节点名映射
var CONNECTION_LIST_MAP:Array
##节点实例缓存
var NODE_INST:Dictionary
##选中的节点名
var NODE_INST_SELECTED:Array
##当前节点
var current_node:String = "StartNode":
	set(n):
		current_node=n
		running_node_changed.emit(n)
##上一个节点
var last_node:String
##endregion

##主视图实例
var WORK_SPACE
##支持的数据类型
enum VAR_TYPE {
	STRING = TYPE_STRING,
	FLOAT = TYPE_FLOAT,
	INT = TYPE_INT,
	BOOL = TYPE_BOOL,
	ARRAY = TYPE_ARRAY,
	DICT = TYPE_DICTIONARY,
	RES = TYPE_OBJECT,
	V2 = TYPE_VECTOR2
}
##数据类型自定义配置
var VAR_TYPE_DIC:Dictionary= {
	4 : ["String",TYPE_STRING,[0]],
	3 : ["float",TYPE_FLOAT,[0,6,7,8,9,12]],
	2 : ["int",TYPE_INT,[0,6,7,8,9,12]],
	1 : ["bool",TYPE_BOOL,[0]],
	28 : ["Array",TYPE_ARRAY,[0,6,7]],
	27 : ["Dictionary",TYPE_DICTIONARY,[0,6,7]],
	24 : ["Resource",TYPE_OBJECT,[0]],
	5 : ["Vector2",TYPE_VECTOR2,[0,6,7,8,9]],
}
##支持的判断数据类型
enum CONDITION_TYPE {
	EQUAL = 0,
	NOT_EQUAL = 1,
	LESS = 2,
	LESS_EQUAL = 3,
	GREATER = 4,
	GREATER_EQUAL = 5,
	NOT = 23,
	IN = 24,
}
##条件连接类型
enum CONDITION_LINK_TYPE{
	AND = 20,
	OR = 21,
}
##条件连接字典
var CONDITION_LINK_TYPE_DIC:Dictionary= {
	20 : ["and",OP_AND],
	21 : ["or",OP_OR],
}
##判断类型字典
var CONDITION_TYPE_DIC:Dictionary= {
	0 : ["==",OP_EQUAL],
	1 : ["!=",OP_NOT_EQUAL],
	2 : ["<",OP_LESS],
	3 : ["<=",OP_LESS_EQUAL],
	4 : [">",OP_GREATER],
	5 : [">=",OP_GREATER_EQUAL],
	23 : ["not",OP_NOT],
	24 : ["in",OP_IN],
}
##Set类型
enum SET_TYPE {
	EQUAL = 0,
	ADD = 6,
	SUBTRACT = 7,
	MULTIPLY = 8,
	DIVIDE = 9,
	MODULE = 12,
}
##set类型字典
var SET_TYPE_DIC:Dictionary= {
	0 : ["=",0],
	6 : ["+=",OP_ADD],
	7 : ["-=",OP_SUBTRACT],
	8 : ["×=",OP_MULTIPLY],
	9 : ["÷=",OP_DIVIDE],
	12 : ["%=",OP_MODULE],
}
##目标全局脚本的方法 [方法名,[{参数名1:类型},{参数名2:类型}],返回值类型]
var CUTSCENE_BUS_METHOD:Array
##指定用于储存可调用方法的全局脚本[脚本1,脚本2]
var METHOD_BUSES:Array
##目标全局脚本的变量
var CUTSCENE_BUS_STATE:Dictionary
##指定用于储存可调用变量的全局脚本
var STATE_BUSES:Array
##聚合数据缓存
var COMBINE_DATAS:Dictionary = {}

##根据类型将string转换为对应变量
func string_2_var(from_var:String,type:int=0):
	match type:
		TYPE_STRING:
			return str(from_var)
		TYPE_FLOAT:
			return float(from_var)
		TYPE_INT:
			return int(from_var)
		TYPE_BOOL:
			return bool(int(from_var)) or from_var.to_lower() == "true"
		TYPE_ARRAY:
			var v =  json_2_var(from_var)
			if typeof(v) == TYPE_ARRAY:
				return v
			else:
				ACTION_LOG = "转出类型错误,应为[Array],实际为:[%s]" %typeof(v)
				return null
		TYPE_DICTIONARY:
			var v =  json_2_var(from_var)
			if typeof(v) == TYPE_DICTIONARY:
				return v
			else:
				ACTION_LOG = "转出类型错误,应为[Dictionary],实际为:[%s]" %typeof(v)
				return null
		TYPE_VECTOR2:
				var v2_list = json_2_var(from_var)
				return Vector2(v2_list[0],v2_list[1])
		TYPE_OBJECT:
			if  ResourceLoader.exists(from_var):
				var res = ResourceLoader.load(from_var)
				return res	
			else :
				ACTION_LOG = "资源文件不存在![%s]" %from_var
				return null	
##json转变量				
func json_2_var(json_string):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		return data_received
	else:
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
##配置文件目录
const CONFIG_DATA_FILE_PATH = "user://Cutscener/config.data"
##配置文件内容数据
var CONFIG_DATA_DIC:Dictionary={
	"run_type":0,
	"method_bus":[],
	"state_bus":[],
	"save_file_config":"",	
}
##默认存档名
const SAVE_FILE_NAME = "save.json"
##默认存档目录
const USER_PATH = "user://"
##日志
var ACTION_LOG:String:
	set(s):
		ACTION_LOG = s + "\n" + ACTION_LOG
		log_change.emit(s)
		print(s)
			
##文件配置字典		
var FILE_SYS_DIC:Dictionary = {
	"file_history":[],#文件历史
	"curren_save_name":"NA",#当前存档名
	"current_save_path":"NA",#当前存档路径
	"current_save_file_path":"NA",#当前存档目录+文件名
}
var FILE_HISTORY:Array:
	set(list):
		FILE_HISTORY = list
		file_history_changed.emit()
##已分解的聚合节所链接的存档文件
var DELETE_COMBINE_NODE_SAVE_FILE_NAME:Dictionary
##主视图
var GRAPH_EDITOR:GraphEdit
##初始化
func preset():
	NODE_INST.clear()
	current_node == "StartNode"
	FILE_SYS_DIC["curren_save_name"] = "NA"
	FILE_SYS_DIC["current_save_path"] = "NA"
	FILE_SYS_DIC["current_save_file_path"] = "NA"
	NODE_INST_SELECTED.clear()
	DELETE_COMBINE_NODE_SAVE_FILE_NAME.clear()
	ACTION_LOG = ""

func popup(text,title:String = "请确认"):
	WORK_SPACE.popup_dialog.dialog_text = text
	WORK_SPACE.popup_dialog.title = title
	WORK_SPACE.popup_dialog.show()
	await WORK_SPACE.popup_dialog.finished
	return WORK_SPACE.popup_dialog.ok

func _ready() -> void:
	var dic = load_json(CONFIG_DATA_FILE_PATH)
	if !dic:return
	if dic.has("method_bus"):
		CONFIG_DATA_DIC["method_bus"] = dic["method_bus"]
	if dic.has("state_bus"):
		CONFIG_DATA_DIC["state_bus"] = dic["state_bus"]
	CutscenerGlobal.METHOD_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["method_bus"]
	CutscenerGlobal.STATE_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["state_bus"]
	refresh_setting_autoload_config.emit()
	
func load_json(path):
	if !FileAccess.file_exists(CutscenerGlobal.CONFIG_DATA_FILE_PATH):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if OK!=error:
		CutscenerGlobal.ACTION_LOG = "执行器载入json数据失败![%s]" %error
	var data_received = json.data as Dictionary
	return data_received
var REPLACEMENTS_REGEX: RegEx = RegEx.create_from_string("{{(.*?)}}")

func get_real_arg(a_name:String,a_type):
	if a_type == TYPE_STRING:
		var global_vs:Array
		global_vs = REPLACEMENTS_REGEX.search_all(a_name)
		if global_vs.is_empty():return a_name
		for global_v in global_vs:
			var o_v = global_v.strings[0]
			var v:String = str(get_property_value(global_v.strings[0]))
			a_name = a_name.replacen(o_v,v)
		return a_name
	else :
		if a_name.begins_with("{{") and a_name.ends_with("}}"):
			return get_property_value(a_name)
		else:
			return string_2_var(a_name,a_type)
			
func get_property_value(p_name:String):
	var p = p_name.replace("{","").replace("}","").replace(" ","")
	if STATE_BUSES.is_empty():return
	for node in STATE_BUSES:
		if !get_tree().get_root().has_node(node):continue
		var value = get_tree().get_root().get_node(node).get(p)
		if null==value:
			continue
		return value
	
