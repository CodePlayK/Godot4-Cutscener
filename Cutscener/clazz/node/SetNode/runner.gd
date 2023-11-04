@tool
extends Node
var node_type = 2
signal finished()
var condition_result:bool = true
enum ARGS_INDEX {
	ParamIndex = 0,
	ParamTypeIndex = 1,
	SetTypeIndex = 2,
	Param2Index = 3,
	ExportIndex = 4,
}
func run(dic):
	#必须等待.1秒否则有可能接收不到finish信号
	##CutscenerGlobal.ACTION_LOG = "------SetRunner[%s]正在运行!------" %dic["title"]
	var props:Array = dic["props"]
	if dic.has(CutscenerGlobal.current_combine_node_name+"_props"):
		props = dic[CutscenerGlobal.current_combine_node_name+"_props"]
		#CutscenerGlobal.ACTION_LOG = "当前正在运行嵌套![%s]" %CutscenerGlobal.current_combine_node_name
	for prop in props:
		var real_to_var = set_by_set_type(prop)
	await RenderingServer.frame_post_draw
	if float(dic["timer"])>0:
		await get_tree().create_timer(float(dic["timer"])).timeout
	##CutscenerGlobal.ACTION_LOG = "------SetRunner[%s]运行完毕!------" %dic["title"]
	finished.emit(dic["name"])
	pass

func set_by_set_type(prop:Array):
	var to_var
	var bus = get_tree().get_root().get_node(prop[ARGS_INDEX.ParamIndex].get_slice(".",0))
	var current_var = bus.get(prop[ARGS_INDEX.ParamIndex].get_slice(".",1))
	var taget_var = CutscenerGlobal.get_real_arg(prop[ARGS_INDEX.Param2Index],prop[ARGS_INDEX.ParamTypeIndex])
	var set_type:int = prop[ARGS_INDEX.SetTypeIndex]
	var param_type:int = prop[ARGS_INDEX.ParamTypeIndex]
	match set_type:
		0:#=
			to_var = taget_var
		6:#+=
			match param_type:
				27:#字典类型则调用合并方法,会覆盖重复的key
					current_var.merge(taget_var,true)
					to_var = current_var
				_:
					to_var = current_var+taget_var
		7:#-=
			match param_type:
				28:#Array类型则调用清除方法,会清除存在于目标字典中的对象
					for v in taget_var:
						current_var.erase(v)
					to_var = current_var
				27:#字典类型则调用清除方法,会清除存在于目标字典中的key
					for key in taget_var.keys():
						current_var.erase(key)
					to_var = current_var
				_:
					to_var = current_var-taget_var
		8:#×=
			to_var = current_var*taget_var
		9:#÷=
			to_var = current_var/taget_var
		12:#%
			to_var = current_var%taget_var
	CutscenerGlobal.ACTION_LOG = " - Set:[%s]->[%s][%s]->[%s]" %[current_var,CutscenerGlobal.SET_TYPE_DIC[int(set_type)][0],str(taget_var),str(to_var)]
	bus.set(prop[ARGS_INDEX.ParamIndex].get_slice(".",1),to_var)
