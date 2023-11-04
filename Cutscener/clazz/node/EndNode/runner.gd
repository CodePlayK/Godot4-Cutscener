@tool
extends Node
var node_type = 4
signal finished
var condition_result:bool = true
func run(dic):
	await RenderingServer.frame_post_draw
	##CutscenerGlobal.ACTION_LOG = "------EndRunner[%s]正在运行!------" %dic["title"]
	CutscenerGlobal.cutscener_ended.emit()
	##CutscenerGlobal.ACTION_LOG = "------运行结束~------"
	finished.emit()
	pass
