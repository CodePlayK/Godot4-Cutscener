@tool
extends BaseGraphNode
func init_var():
	node_type=CutscenerGlobal.NODES.END_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["EndNode",self.title]
