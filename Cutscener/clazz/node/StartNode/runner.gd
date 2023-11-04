@tool
extends Node
var node_type = 0
signal finished
var condition_result:bool = true
func run(dic):
	await RenderingServer.frame_post_draw
	##CutscenerGlobal.ACTION_LOG = "------开始运行~------"
	CutscenerGlobal.cutscener_started.emit()
	##CutscenerGlobal.ACTION_LOG = "------StartRunner[%s]正在运行!------" %dic["title"]
	finished.emit()
