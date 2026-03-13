## Clickdev PlugPlay — plugin.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0
## License: MIT

@tool
extends EditorPlugin

const PLUGIN_NAME    := "Clickdev PlugPlay"
const PLUGIN_VERSION := "1.0.0"

var _panel: Control = null

func _enter_tree() -> void:
	print("[Clickdev PlugPlay v%s] — by Ahmad Ilham Kurniawan" % PLUGIN_VERSION)

	add_custom_type(
		"ClickdevObject",
		"CharacterBody2D",
		preload("res://addons/clickdev_plugplay/nodes/ClickdevObject.gd"),
		null
	)
	add_custom_type(
		"ClickdevEventSheet",
		"Node",
		preload("res://addons/clickdev_plugplay/nodes/ClickdevEventSheet.gd"),
		null
	)
	add_custom_type(
		"ClickdevTimer",
		"Timer",
		preload("res://addons/clickdev_plugplay/nodes/ClickdevTimer.gd"),
		null
	)

	var script: GDScript = load("res://addons/clickdev_plugplay/event_editor/EventEditorPanel.gd")
	_panel = script.new()
	_panel.name = "ClickdevPanel"
	add_control_to_bottom_panel(_panel, "🎮 Clickdev")

	print("[Clickdev PlugPlay] Ready. Add ClickdevEventSheet to your scene to start.")

func _exit_tree() -> void:
	if is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
	_panel = null
	remove_custom_type("ClickdevObject")
	remove_custom_type("ClickdevEventSheet")
	remove_custom_type("ClickdevTimer")

func _get_plugin_name() -> String:
	return PLUGIN_NAME
