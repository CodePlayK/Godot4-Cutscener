@tool
extends LineEdit


func _on_text_changed(new_text: String) -> void:
	CutscenerGlobal.param_modify.emit(new_text)


func _on_focus_entered() -> void:
	CutscenerGlobal.param_focus_enter.emit(self)


func _on_focus_exited() -> void:
	CutscenerGlobal.param_focus_exit.emit()
