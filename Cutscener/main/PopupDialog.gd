@tool
extends ConfirmationDialog
var ok :bool= false
signal finished

func _on_confirmed() -> void:
	ok = true
	finished.emit()

func _on_canceled() -> void:
	ok = false
	finished.emit()
