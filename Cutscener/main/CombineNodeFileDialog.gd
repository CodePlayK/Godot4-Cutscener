@tool
extends FileDialog
var ok :bool= false
signal finished

func _on_confirmed() -> void:
	if current_file:
		ok = true
	else :
		ok = false
	finished.emit()

func _on_canceled() -> void:
	ok = false
	finished.emit()

func _on_file_selected(path: String) -> void:
	ok = true
	finished.emit()
