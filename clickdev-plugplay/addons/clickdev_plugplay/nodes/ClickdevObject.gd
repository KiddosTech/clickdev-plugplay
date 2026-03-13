## ClickdevObject.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0
##
## Base node for game objects in Clickdev.
## Works like an "Active Object" in Clickteam Fusion.

@tool
class_name ClickdevObject
extends CharacterBody2D

@export var object_name: String = "Object"

@export_group("Physics")
@export var gravity_enabled:  bool  = false
@export var gravity_strength: float = 980.0
@export var max_fall_speed:   float = 1500.0

@export_group("Clickdev Values")
@export var value_a: int    = 0
@export var value_b: int    = 0
@export var value_c: int    = 0
@export var string_a: String = ""
@export var string_b: String = ""

var _extra: Dictionary = {}

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if gravity_enabled:
		velocity.y = minf(velocity.y + gravity_strength * delta, max_fall_speed)
	move_and_slide()

# ── Helper methods available from generated code ──

func set_var(key: String, val: Variant) -> void:
	_extra[key] = val

func get_var(key: String, default: Variant = 0) -> Variant:
	return _extra.get(key, default)

func add_to_var(key: String, amount: Variant) -> void:
	_extra[key] = get_var(key, 0) + amount

func distance_to_node(other: Node2D) -> float:
	return global_position.distance_to(other.global_position)
