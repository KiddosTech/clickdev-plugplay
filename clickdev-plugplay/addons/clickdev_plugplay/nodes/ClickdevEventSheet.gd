## ClickdevEventSheet.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0
##
## Add this node to your scene to use Clickdev events.
## Select it in the Scene panel to open the event editor below.

@tool
class_name ClickdevEventSheet
extends Node

## Serialised event data — edited via the Clickdev panel (do not edit manually)
@export var event_data: Array = []

## When true, events are compiled and executed automatically on scene start
@export var auto_run: bool = true

var _runtime: Node = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if auto_run and not event_data.is_empty():
		_compile_and_run()

func _compile_and_run() -> void:
	var blocks: Array = []
	for d in event_data:
		blocks.append(ClickdevCodeGen.EventBlock.from_dict(d))

	var code: String = ClickdevCodeGen.generate(blocks)

	var script := GDScript.new()
	script.source_code = code
	var err: int = script.reload()
	if err != OK:
		push_error("[Clickdev] Compile error in '%s': %s" % [name, error_string(err)])
		return

	_runtime = script.new()
	_runtime.name = "_ClickdevRuntime"
	add_child(_runtime)

# Called by the editor panel after saving events
func save_events(data: Array) -> void:
	event_data = data
	notify_property_list_changed()

# Returns deserialised EventBlock objects for the editor panel
func get_blocks() -> Array:
	var result: Array = []
	for d in event_data:
		result.append(ClickdevCodeGen.EventBlock.from_dict(d))
	return result

# Returns the GDScript that would be generated (for the Code Preview tab)
func preview_code() -> String:
	var blocks: Array = []
	for d in event_data:
		blocks.append(ClickdevCodeGen.EventBlock.from_dict(d))
	return ClickdevCodeGen.generate(blocks)
