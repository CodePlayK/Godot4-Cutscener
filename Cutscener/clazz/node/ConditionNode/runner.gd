@tool
extends Node
var node_type = 3
signal finished()
var condition_result:bool = true
##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	ConditionLinkTypeIndex = 0,
	ParamIndex = 1,
	ParamTypeIndex = 2,
	ConditionTypeIndex = 3,
	Param2Index = 4,
	ExportIndex = 5,
}

##prop = [条件连接类型,对比的变量名,变量类型,条件类型,目标值]
func run(dic):
	condition_result = true
	#必须等待.1秒否则有可能接收不到finish信号
	await RenderingServer.frame_post_draw
	var running_node_name = dic["name"]
	##CutscenerGlobal.ACTION_LOG = "------ConditionRunner [%s]正在运行!------" %running_node_name
	var props:Array = dic["props"]
	if dic.has(CutscenerGlobal.current_combine_node_name+"_props"):
		props = dic[CutscenerGlobal.current_combine_node_name+"_props"]
		#CutscenerGlobal.ACTION_LOG = "当前正在运行嵌套![%s]" %CutscenerGlobal.current_combine_node_name
	for prop in props:
		var link_type = prop[ARGS_INDEX.ConditionLinkTypeIndex]
		var flag = handle_condition(prop)
		if link_type == OP_OR:
			if flag:
				condition_result = true
				break
		else:
			if !flag:
				condition_result = false
	CutscenerGlobal.ACTION_LOG = " - 判断结果 == [%s]" %condition_result 
	if float(dic["timer"])>0:
		await get_tree().create_timer(float(dic["timer"])).timeout
	#CutscenerGlobal.ACTION_LOG = "------ConditionRunner [%s]运行完毕!------" %running_node_name
	finished.emit(running_node_name)
	
##处理判断条件
func handle_condition(prop:Array):
	var bus = get_tree().get_root().get_node(prop[ARGS_INDEX.ParamIndex].get_slice(".",0))
	var link_type = prop[ARGS_INDEX.ConditionLinkTypeIndex]
	var from_var = prop[ARGS_INDEX.ParamIndex].get_slice(".",1)
	var var_type = prop[ARGS_INDEX.ParamTypeIndex]
	var condition_type = prop[ARGS_INDEX.ConditionTypeIndex]
	var to_var = prop[ARGS_INDEX.Param2Index]
	var real_to_var = CutscenerGlobal.get_real_arg(prop[ARGS_INDEX.Param2Index],prop[ARGS_INDEX.ParamTypeIndex])
	var real_from_var = bus.get(from_var)
	CutscenerGlobal.ACTION_LOG =" - 判断:[%s]--[%s]--[%s]" %[str(real_from_var),CutscenerGlobal.CONDITION_TYPE_DIC[int(condition_type)][0],str(real_to_var)]
	if condition_type == CutscenerGlobal.CONDITION_TYPE.EQUAL:
		return real_from_var == real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.NOT_EQUAL:
		return real_from_var != real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.LESS:
		return real_from_var < real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.LESS_EQUAL:
		return real_from_var <= real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.GREATER:
		return real_from_var > real_to_var
	elif condition_type == OP_GREATER_EQUAL:
		return real_from_var >= real_to_var
	elif condition_type == OP_IN:
		return real_from_var in real_to_var
	elif condition_type == OP_NOT:
		return real_from_var not in real_to_var
