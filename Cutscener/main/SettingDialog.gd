@tool
extends AcceptDialog

func _on_confirmed() -> void:
	CutscenerGlobal.METHOD_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["method_bus"]
	CutscenerGlobal.STATE_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["state_bus"]
	CutscenerGlobal.load_all_method_state_from_global.emit()

func _on_canceled() -> void:
	_on_confirmed()
