@tool
extends Node
var node_type = 101
signal finished
signal run_combine_node
var continued:bool = false
var running_combine_node_name:String
var condition_result:bool = true
func _ready() -> void:
	CutscenerGlobal.run_combine_finished.connect(on_run_combine_finished)
	
func run(dic):
	await RenderingServer.frame_post_draw
	##CutscenerGlobal.ACTION_LOG = "------CombineRunner[%s]正在运行!------" %dic["title"]
	run_combine_node.emit(dic["data_node_name"],dic["name"])
	running_combine_node_name = dic["name"]

##聚合节点完成事件	
func on_run_combine_finished(combine_node_name):
	if !running_combine_node_name == combine_node_name:
		#CutscenerGlobal.ACTION_LOG = "[%s]非自身完成[%s]!" %[running_combine_node_name,combine_node_name]
		return
	#CutscenerGlobal.ACTION_LOG = "[%s]完成[%s]!" %[running_combine_node_name,combine_node_name]
	continued = true
	
func _physics_process(delta: float) -> void:
	if continued!=true:return#阻塞等待继续
	##CutscenerGlobal.ACTION_LOG = "------[%s]嵌套运行结束~------" %running_combine_node_name
	continued=false
	finished.emit(running_combine_node_name)
