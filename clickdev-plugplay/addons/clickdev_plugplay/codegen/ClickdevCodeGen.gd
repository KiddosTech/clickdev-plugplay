## ClickdevCodeGen.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0
## Translates visual event blocks into GDScript code.

class_name ClickdevCodeGen
extends RefCounted


# ═══════════════════════════════════════════════════════════════════
#  DATA STRUCTURES
# ═══════════════════════════════════════════════════════════════════

class ConditionBlock:
	var type:   String     = ""
	var params: Dictionary = {}
	var negate: bool       = false

	func _init(t: String = "", p: Dictionary = {}, n: bool = false) -> void:
		type   = t
		params = p
		negate = n

	func to_dict() -> Dictionary:
		return { "type": type, "params": params, "negate": negate }

	static func from_dict(d: Dictionary) -> ConditionBlock:
		return ConditionBlock.new(
			d.get("type",   ""),
			d.get("params", {}),
			d.get("negate", false)
		)


class ActionBlock:
	var type:   String     = ""
	var params: Dictionary = {}

	func _init(t: String = "", p: Dictionary = {}) -> void:
		type   = t
		params = p

	func to_dict() -> Dictionary:
		return { "type": type, "params": params }

	static func from_dict(d: Dictionary) -> ActionBlock:
		return ActionBlock.new(
			d.get("type",   ""),
			d.get("params", {})
		)


class EventBlock:
	var label:   String = "New Event"
	var enabled: bool   = true
	var conditions: Array = []
	var actions:    Array = []

	func to_dict() -> Dictionary:
		var c: Array = []
		for x in conditions:
			c.append(x.to_dict())
		var a: Array = []
		for x in actions:
			a.append(x.to_dict())
		return { "label": label, "enabled": enabled, "conditions": c, "actions": a }

	static func from_dict(d: Dictionary) -> EventBlock:
		var b := EventBlock.new()
		b.label   = d.get("label",   "Event")
		b.enabled = d.get("enabled", true)
		for c in d.get("conditions", []):
			b.conditions.append(ConditionBlock.from_dict(c))
		for a in d.get("actions", []):
			b.actions.append(ActionBlock.from_dict(a))
		return b


# ═══════════════════════════════════════════════════════════════════
#  CONDITION CATEGORIES & CATALOGUE
#  NOTE: Must be static func (not const) so external scripts can read them.
# ═══════════════════════════════════════════════════════════════════

static func get_condition_categories() -> Array:
	return [
		{ "id": "general",   "label": "🔵  General"   },
		{ "id": "input",     "label": "🎮  Input"      },
		{ "id": "object",    "label": "📦  Object"     },
		{ "id": "collision", "label": "💥  Collision"  },
		{ "id": "variable",  "label": "🔢  Variable"   },
		{ "id": "timer",     "label": "⏱  Timer"      },
		{ "id": "scene",     "label": "🎬  Scene"      },
		{ "id": "math",      "label": "➕  Math"       },
	]

static func get_condition_catalogue() -> Dictionary:
	return {
		# ── General ─────────────────────────────────────────────────
		"always":
			{ "label": "Always (every frame)",     "category": "general",
			  "params": [],
			  "code":  "true" },
		"on_start":
			{ "label": "At start of scene",        "category": "general",
			  "params": [],
			  "code":  "_cd_started" },
		"every_n_frames":
			{ "label": "Every N frames",            "category": "general",
			  "params": ["frames"],
			  "code":  "Engine.get_process_frames() % int({frames}) == 0" },
		"random_chance":
			{ "label": "Random chance (0.0 – 1.0)", "category": "general",
			  "params": ["chance"],
			  "code":  "randf() < float({chance})" },

		# ── Input — Keyboard ────────────────────────────────────────
		"key_held":
			{ "label": "Key held down",             "category": "input",
			  "params": ["key"],
			  "code":  "Input.is_key_pressed(KEY_{key})" },
		"key_just_pressed":
			{ "label": "Key just pressed",          "category": "input",
			  "params": ["action"],
			  "code":  "Input.is_action_just_pressed(\"{action}\")" },
		"key_just_released":
			{ "label": "Key just released",         "category": "input",
			  "params": ["action"],
			  "code":  "Input.is_action_just_released(\"{action}\")" },
		"action_held":
			{ "label": "Action held (Input Map)",   "category": "input",
			  "params": ["action"],
			  "code":  "Input.is_action_pressed(\"{action}\")" },

		# ── Input — Mouse ───────────────────────────────────────────
		"mouse_left_held":
			{ "label": "Left mouse held",           "category": "input",
			  "params": [],
			  "code":  "Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)" },
		"mouse_right_held":
			{ "label": "Right mouse held",          "category": "input",
			  "params": [],
			  "code":  "Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)" },
		"mouse_left_clicked":
			{ "label": "Left mouse just clicked",   "category": "input",
			  "params": [],
			  "code":  "Input.is_action_just_pressed(\"click\")" },

		# ── Object ──────────────────────────────────────────────────
		"obj_visible":
			{ "label": "Object is visible",         "category": "object",
			  "params": ["object"],
			  "code":  "{object}.visible" },
		"obj_exists":
			{ "label": "Object exists in scene",    "category": "object",
			  "params": ["object"],
			  "code":  "is_instance_valid({object})" },
		"obj_x_gt":
			{ "label": "Object X > value",          "category": "object",
			  "params": ["object", "value"],
			  "code":  "{object}.position.x > {value}" },
		"obj_x_lt":
			{ "label": "Object X < value",          "category": "object",
			  "params": ["object", "value"],
			  "code":  "{object}.position.x < {value}" },
		"obj_y_gt":
			{ "label": "Object Y > value",          "category": "object",
			  "params": ["object", "value"],
			  "code":  "{object}.position.y > {value}" },
		"obj_y_lt":
			{ "label": "Object Y < value",          "category": "object",
			  "params": ["object", "value"],
			  "code":  "{object}.position.y < {value}" },

		# ── Collision ───────────────────────────────────────────────
		"on_floor":
			{ "label": "Object on floor",           "category": "collision",
			  "params": ["object"],
			  "code":  "{object}.is_on_floor()" },
		"on_wall":
			{ "label": "Object on wall",            "category": "collision",
			  "params": ["object"],
			  "code":  "{object}.is_on_wall()" },
		"on_ceiling":
			{ "label": "Object on ceiling",         "category": "collision",
			  "params": ["object"],
			  "code":  "{object}.is_on_ceiling()" },
		"is_colliding":
			{ "label": "Object is colliding (any)", "category": "collision",
			  "params": ["object"],
			  "code":  "({object}.is_on_floor() or {object}.is_on_wall() or {object}.is_on_ceiling())" },

		# ── Variable ────────────────────────────────────────────────
		"var_eq":
			{ "label": "Variable equals",           "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} == {value}" },
		"var_neq":
			{ "label": "Variable not equal",        "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} != {value}" },
		"var_gt":
			{ "label": "Variable greater than",     "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} > {value}" },
		"var_lt":
			{ "label": "Variable less than",        "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} < {value}" },
		"var_between":
			{ "label": "Variable between A and B",  "category": "variable",
			  "params": ["var", "min", "max"],
			  "code":  "({var} >= {min} and {var} <= {max})" },
		"str_eq":
			{ "label": "String equals",             "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} == \"{value}\"" },

		# ── Timer ───────────────────────────────────────────────────
		"timer_done":
			{ "label": "Timer has finished",        "category": "timer",
			  "params": ["timer"],
			  "code":  "{timer}.is_stopped()" },
		"timer_running":
			{ "label": "Timer is running",          "category": "timer",
			  "params": ["timer"],
			  "code":  "not {timer}.is_stopped()" },

		# ── Scene ───────────────────────────────────────────────────
		"is_paused":
			{ "label": "Game is paused",            "category": "scene",
			  "params": [],
			  "code":  "get_tree().paused" },

		# ── Math ────────────────────────────────────────────────────
		"custom_expr":
			{ "label": "Custom expression is true", "category": "math",
			  "params": ["expression"],
			  "code":  "({expression})" },
	}


# ═══════════════════════════════════════════════════════════════════
#  ACTION CATEGORIES & CATALOGUE
# ═══════════════════════════════════════════════════════════════════

static func get_action_categories() -> Array:
	return [
		{ "id": "movement",  "label": "🏃  Movement"  },
		{ "id": "object",    "label": "📦  Object"    },
		{ "id": "animation", "label": "🎞  Animation" },
		{ "id": "sound",     "label": "🔊  Sound"     },
		{ "id": "variable",  "label": "🔢  Variable"  },
		{ "id": "timer",     "label": "⏱  Timer"     },
		{ "id": "scene",     "label": "🎬  Scene"     },
		{ "id": "system",    "label": "⚙  System"    },
		{ "id": "debug",     "label": "🐛  Debug"     },
	]

static func get_action_catalogue() -> Dictionary:
	return {
		# ── Movement ────────────────────────────────────────────────
		"move_left":
			{ "label": "Move left",                  "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.x = -{speed}" },
		"move_right":
			{ "label": "Move right",                 "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.x = {speed}" },
		"move_up":
			{ "label": "Move up",                    "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.y = -{speed}" },
		"move_down":
			{ "label": "Move down",                  "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.y = {speed}" },
		"stop_x":
			{ "label": "Stop horizontal movement",   "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.velocity.x = 0" },
		"stop_y":
			{ "label": "Stop vertical movement",     "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.velocity.y = 0" },
		"stop_all":
			{ "label": "Stop all movement",          "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.velocity = Vector2.ZERO" },
		"jump":
			{ "label": "Jump",                       "category": "movement",
			  "params": ["object", "force"],
			  "code":  "if {object}.is_on_floor(): {object}.velocity.y = -{force}" },
		"set_velocity":
			{ "label": "Set velocity (X, Y)",        "category": "movement",
			  "params": ["object", "x", "y"],
			  "code":  "{object}.velocity = Vector2({x}, {y})" },
		"set_vel_x":
			{ "label": "Set horizontal velocity",    "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.x = {speed}" },
		"set_vel_y":
			{ "label": "Set vertical velocity",      "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity.y = {speed}" },
		"bounce_x":
			{ "label": "Bounce horizontally",        "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.velocity.x *= -1" },
		"bounce_y":
			{ "label": "Bounce vertically",          "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.velocity.y *= -1" },
		"move_to_mouse":
			{ "label": "Move toward mouse",          "category": "movement",
			  "params": ["object", "speed"],
			  "code":  "{object}.velocity = {object}.global_position.direction_to({object}.get_global_mouse_position()) * {speed}" },
		"look_at_mouse":
			{ "label": "Look at mouse",              "category": "movement",
			  "params": ["object"],
			  "code":  "{object}.look_at({object}.get_global_mouse_position())" },

		# ── Object ──────────────────────────────────────────────────
		"set_pos":
			{ "label": "Set position (X, Y)",        "category": "object",
			  "params": ["object", "x", "y"],
			  "code":  "{object}.position = Vector2({x}, {y})" },
		"set_pos_x":
			{ "label": "Set X position",             "category": "object",
			  "params": ["object", "x"],
			  "code":  "{object}.position.x = {x}" },
		"set_pos_y":
			{ "label": "Set Y position",             "category": "object",
			  "params": ["object", "y"],
			  "code":  "{object}.position.y = {y}" },
		"add_pos_x":
			{ "label": "Add to X position",          "category": "object",
			  "params": ["object", "amount"],
			  "code":  "{object}.position.x += {amount}" },
		"add_pos_y":
			{ "label": "Add to Y position",          "category": "object",
			  "params": ["object", "amount"],
			  "code":  "{object}.position.y += {amount}" },
		"set_rotation":
			{ "label": "Set rotation (degrees)",     "category": "object",
			  "params": ["object", "angle"],
			  "code":  "{object}.rotation_degrees = {angle}" },
		"add_rotation":
			{ "label": "Rotate by degrees",          "category": "object",
			  "params": ["object", "angle"],
			  "code":  "{object}.rotation_degrees += {angle}" },
		"set_scale":
			{ "label": "Set scale (X, Y)",           "category": "object",
			  "params": ["object", "x", "y"],
			  "code":  "{object}.scale = Vector2({x}, {y})" },
		"show_obj":
			{ "label": "Show object",                "category": "object",
			  "params": ["object"],
			  "code":  "{object}.visible = true" },
		"hide_obj":
			{ "label": "Hide object",                "category": "object",
			  "params": ["object"],
			  "code":  "{object}.visible = false" },
		"toggle_visible":
			{ "label": "Toggle visibility",          "category": "object",
			  "params": ["object"],
			  "code":  "{object}.visible = not {object}.visible" },
		"destroy":
			{ "label": "Destroy object",             "category": "object",
			  "params": ["object"],
			  "code":  "{object}.queue_free()" },
		"set_opacity":
			{ "label": "Set opacity (0.0 – 1.0)",    "category": "object",
			  "params": ["object", "alpha"],
			  "code":  "{object}.modulate.a = {alpha}" },
		"flip_h":
			{ "label": "Flip horizontally",          "category": "object",
			  "params": ["object"],
			  "code":  "{object}.scale.x *= -1" },
		"flip_v":
			{ "label": "Flip vertically",            "category": "object",
			  "params": ["object"],
			  "code":  "{object}.scale.y *= -1" },

		# ── Animation ───────────────────────────────────────────────
		"play_anim":
			{ "label": "Play animation",             "category": "animation",
			  "params": ["object", "anim"],
			  "code":  "{object}.play(\"{anim}\")" },
		"stop_anim":
			{ "label": "Stop animation",             "category": "animation",
			  "params": ["object"],
			  "code":  "{object}.stop()" },
		"pause_anim":
			{ "label": "Pause animation",            "category": "animation",
			  "params": ["object"],
			  "code":  "{object}.pause()" },
		"set_anim_speed":
			{ "label": "Set animation speed scale",  "category": "animation",
			  "params": ["object", "speed"],
			  "code":  "{object}.speed_scale = {speed}" },
		"set_frame":
			{ "label": "Set animation frame",        "category": "animation",
			  "params": ["object", "frame"],
			  "code":  "{object}.frame = {frame}" },

		# ── Sound ───────────────────────────────────────────────────
		"play_sound":
			{ "label": "Play sound",                 "category": "sound",
			  "params": ["node"],
			  "code":  "{node}.play()" },
		"stop_sound":
			{ "label": "Stop sound",                 "category": "sound",
			  "params": ["node"],
			  "code":  "{node}.stop()" },
		"set_volume":
			{ "label": "Set volume (dB)",            "category": "sound",
			  "params": ["node", "db"],
			  "code":  "{node}.volume_db = {db}" },
		"set_pitch":
			{ "label": "Set pitch scale",            "category": "sound",
			  "params": ["node", "pitch"],
			  "code":  "{node}.pitch_scale = {pitch}" },

		# ── Variable ────────────────────────────────────────────────
		"set_var":
			{ "label": "Set variable",               "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} = {value}" },
		"add_var":
			{ "label": "Add to variable",            "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} += {value}" },
		"sub_var":
			{ "label": "Subtract from variable",     "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} -= {value}" },
		"mul_var":
			{ "label": "Multiply variable",          "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} *= {value}" },
		"div_var":
			{ "label": "Divide variable",            "category": "variable",
			  "params": ["var", "value"],
			  "code":  "{var} /= {value}" },
		"rand_var":
			{ "label": "Set variable to random int", "category": "variable",
			  "params": ["var", "min", "max"],
			  "code":  "{var} = randi_range({min}, {max})" },
		"clamp_var":
			{ "label": "Clamp variable (min – max)", "category": "variable",
			  "params": ["var", "min", "max"],
			  "code":  "{var} = clamp({var}, {min}, {max})" },
		"reset_var":
			{ "label": "Reset variable to 0",        "category": "variable",
			  "params": ["var"],
			  "code":  "{var} = 0" },

		# ── Timer ───────────────────────────────────────────────────
		"start_timer":
			{ "label": "Start timer",                "category": "timer",
			  "params": ["timer", "seconds"],
			  "code":  "{timer}.start({seconds})" },
		"stop_timer":
			{ "label": "Stop timer",                 "category": "timer",
			  "params": ["timer"],
			  "code":  "{timer}.stop()" },

		# ── Scene ───────────────────────────────────────────────────
		"load_scene":
			{ "label": "Load scene",                 "category": "scene",
			  "params": ["path"],
			  "code":  "get_tree().change_scene_to_file(\"{path}\")" },
		"restart_scene":
			{ "label": "Restart current scene",      "category": "scene",
			  "params": [],
			  "code":  "get_tree().reload_current_scene()" },
		"pause_game":
			{ "label": "Pause game",                 "category": "scene",
			  "params": [],
			  "code":  "get_tree().paused = true" },
		"unpause_game":
			{ "label": "Unpause game",               "category": "scene",
			  "params": [],
			  "code":  "get_tree().paused = false" },
		"quit_game":
			{ "label": "Quit game",                  "category": "scene",
			  "params": [],
			  "code":  "get_tree().quit()" },

		# ── System ──────────────────────────────────────────────────
		"set_time_scale":
			{ "label": "Set time scale",             "category": "system",
			  "params": ["scale"],
			  "code":  "Engine.time_scale = {scale}" },
		"call_func":
			{ "label": "Call function on node",      "category": "system",
			  "params": ["node", "function"],
			  "code":  "{node}.{function}()" },
		"emit_signal":
			{ "label": "Emit signal on node",        "category": "system",
			  "params": ["node", "signal_name"],
			  "code":  "{node}.emit_signal(\"{signal_name}\")" },

		# ── Debug ───────────────────────────────────────────────────
		"print_msg":
			{ "label": "Print message",              "category": "debug",
			  "params": ["message"],
			  "code":  "print(\"{message}\")" },
		"print_var":
			{ "label": "Print variable value",       "category": "debug",
			  "params": ["var"],
			  "code":  "print({var})" },
		"print_pos":
			{ "label": "Print object position",      "category": "debug",
			  "params": ["object"],
			  "code":  "print(\"{object}: \", {object}.position)" },
	}


# ═══════════════════════════════════════════════════════════════════
#  CODE GENERATOR
# ═══════════════════════════════════════════════════════════════════

static func generate(event_blocks: Array) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("## AUTO-GENERATED by Clickdev PlugPlay v1.0.0")
	lines.append("## Author: Ahmad Ilham Kurniawan")
	lines.append("## Do NOT edit manually — use the Clickdev event editor.")
	lines.append("extends Node")
	lines.append("")
	lines.append("var _cd_started: bool = false")
	lines.append("")
	lines.append("func _ready() -> void:")
	lines.append("\t_cd_started = true")
	lines.append("")
	lines.append("func _process(_delta: float) -> void:")

	var has_any := false
	for block in event_blocks:
		if not block.enabled:
			continue
		has_any = true
		lines.append("")
		lines.append("\t# ── %s ──" % block.label)
		lines.append("\tif %s:" % _build_conditions(block.conditions))
		if block.actions.is_empty():
			lines.append("\t\tpass")
		else:
			for act in block.actions:
				lines.append("\t\t%s" % _build_action(act))

	if not has_any:
		lines.append("\tpass")

	lines.append("")
	return "\n".join(lines)


static func _build_conditions(conditions: Array) -> String:
	if conditions.is_empty():
		return "true"
	var parts: PackedStringArray = PackedStringArray()
	for cond in conditions:
		var code: String = _build_condition(cond)
		if cond.negate:
			parts.append("(not (%s))" % code)
		else:
			parts.append(code)
	return " and ".join(parts)


static func _build_condition(cond: ConditionBlock) -> String:
	var cat: Dictionary = get_condition_catalogue()
	if not cat.has(cond.type):
		return "true # unknown condition: %s" % cond.type
	return _fill(cat[cond.type]["code"], cond.params)


static func _build_action(act: ActionBlock) -> String:
	var cat: Dictionary = get_action_catalogue()
	if not cat.has(act.type):
		return "pass # unknown action: %s" % act.type
	return _fill(cat[act.type]["code"], act.params)


static func _fill(template: String, params: Dictionary) -> String:
	var result: String = template
	for k: String in params:
		result = result.replace("{%s}" % k, str(params[k]))
	return result
