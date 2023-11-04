@tool
extends Node
var node_type = 1
signal finished()
var condition_result:bool = true
##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	ParamIndex = 0,
	ParamTypeIndex = 1,
	Param2Index = 2,
	ExportIndex = 3,
}

func run(dic):
	condition_result = true
	#必须等待.1秒否则有可能接收不到finish信号
	await get_tree().create_timer(.1).timeout
	await RenderingServer.frame_post_draw
	##CutscenerGlobal.ACTION_LOG = "------SignalRunner[%s]正在运行!------" %dic["title"]
	var global = dic["signal_name"].get_slice(".",0)
	var method = dic["signal_name"].get_slice(".",1)
	var args = dic["props"]
	if dic.has(CutscenerGlobal.current_combine_node_name+"_props"):
		args = dic[CutscenerGlobal.current_combine_node_name+"_props"]
		#CutscenerGlobal.ACTION_LOG = "当前正在运行嵌套![%s]" %CutscenerGlobal.current_combine_node_name
	var return_type = dic["return_type"]
	var real_args:Array
	for arg in args:
		var real_arg = CutscenerGlobal.get_real_arg(arg[ARGS_INDEX.Param2Index],arg[ARGS_INDEX.ParamTypeIndex])
		real_args.append(real_arg)
	CutscenerGlobal.ACTION_LOG = " - 执行:%s%s" %[method,str(real_args)]
	var bus = get_tree().get_root().get_node(global)
	if bus.has_method(method):
		if return_type:
			condition_result = await bus.callv(method,real_args)
		else :
			await bus.callv(method,real_args)
	if float(dic["timer"])>0:
		await get_tree().create_timer(float(dic["timer"])).timeout
	##CutscenerGlobal.ACTION_LOG = "------SignalRunner[%s]运行完毕!------" %dic["title"]
	finished.emit(dic["name"])
