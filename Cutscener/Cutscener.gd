@tool
extends EditorPlugin
var main_scene
var main

func _enter_tree() -> void:
	add_autoload_singleton("CutscenerGlobal", "res://addons/Cutscener/clazz/CutscenerGlobal.gd")
	if Engine.is_editor_hint():
		main_scene = preload("res://addons/Cutscener/main/main.tscn")
		add_custom_type(
			"CutscenerRunner","Node",preload("res://addons/Cutscener/clazz/node/Cutscener/CutscenerRunner.gd"),
			preload("res://addons/Cutscener/resource/runner-logo.png")
		)
		main = main_scene.instantiate()
		main.hide()
		EditorInterface.get_editor_main_screen().add_child(main)
func _exit_tree() -> void:
	if main:
		main.queue_free()
func _has_main_screen():
	return true

func _make_visible(visible):
	main.visible = visible
func _get_plugin_name():
	return "Cutscener"

func _get_plugin_icon():
	return preload("res://addons/Cutscener/resource/logo.svg")

