## EventEditorPanel.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0
##
## The Clickdev visual event editor panel inside Godot.
## Shows at the bottom of the editor when the plugin is active.

@tool
extends Control

# ── State ─────────────────────────────────────────────────────────
var _sheet:          Node   = null   # active ClickdevEventSheet
var _blocks:         Array  = []     # Array of ClickdevCodeGen.EventBlock
var _sel:            int    = -1     # selected block index

# ── Picker state ──────────────────────────────────────────────────
var _pick_kind:      String = ""     # "condition" | "action"
var _pick_block             = null   # EventBlock being edited

# ── UI refs ───────────────────────────────────────────────────────
var _status:         Label
var _main_split:     HSplitContainer
var _empty_lbl:      Label
var _ev_list:        VBoxContainer
var _detail_vbox:    VBoxContainer
var _code_edit:      TextEdit


func _ready() -> void:
	_build_ui()
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.connect(_on_sel_changed)


# ═══════════════════════════════════════════════════════════════════
#  UI BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ── Toolbar ──────────────────────────────────────────────────
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	root.add_child(bar)

	_status = Label.new()
	_status.text = "Select a ClickdevEventSheet node to begin"
	_status.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_status)

	var b_add := Button.new()
	b_add.text = "＋ Add Event"
	b_add.pressed.connect(_on_add_event)
	bar.add_child(b_add)

	var b_save := Button.new()
	b_save.text = "💾 Save"
	b_save.pressed.connect(_on_save)
	bar.add_child(b_save)

	var b_code := Button.new()
	b_code.text = "{ } Code"
	b_code.pressed.connect(_toggle_code)
	bar.add_child(b_code)

	# ── Empty label ───────────────────────────────────────────────
	_empty_lbl = Label.new()
	_empty_lbl.text = "Select a ClickdevEventSheet node in the Scene panel to edit events here."
	_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_empty_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	_empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	root.add_child(_empty_lbl)

	# ── Main split ────────────────────────────────────────────────
	_main_split = HSplitContainer.new()
	_main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_split.split_offset = 290
	_main_split.visible = false
	root.add_child(_main_split)

	# Left — event list
	var lscroll := ScrollContainer.new()
	lscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_main_split.add_child(lscroll)

	_ev_list = VBoxContainer.new()
	_ev_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.add_child(_ev_list)

	# Right — detail + code preview
	var rvbox := VBoxContainer.new()
	rvbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_main_split.add_child(rvbox)

	var rscroll := ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rvbox.add_child(rscroll)

	_detail_vbox = VBoxContainer.new()
	_detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(_detail_vbox)

	var ph := Label.new()
	ph.text = "← Click an event to edit it"
	ph.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	_detail_vbox.add_child(ph)

	_code_edit = TextEdit.new()
	_code_edit.custom_minimum_size.y = 130
	_code_edit.editable = false
	_code_edit.visible  = false
	_code_edit.placeholder_text = "Save events to preview generated GDScript here."
	rvbox.add_child(_code_edit)


# ═══════════════════════════════════════════════════════════════════
#  SELECTION
# ═══════════════════════════════════════════════════════════════════

func _on_sel_changed() -> void:
	_sheet = null
	for node in EditorInterface.get_selection().get_selected_nodes():
		if node.has_method("save_events") and node.has_method("get_blocks"):
			_sheet = node
			break

	if is_instance_valid(_sheet):
		_blocks = _sheet.get_blocks()
		_status.text = "Editing: %s  (%d events)" % [_sheet.name, _blocks.size()]
		_empty_lbl.visible   = false
		_main_split.visible  = true
		_rebuild_list()
	else:
		_status.text = "Select a ClickdevEventSheet node to begin"
		_empty_lbl.visible  = true
		_main_split.visible = false


# ═══════════════════════════════════════════════════════════════════
#  EVENT LIST (left panel)
# ═══════════════════════════════════════════════════════════════════

func _rebuild_list() -> void:
	for c in _ev_list.get_children():
		c.queue_free()
	for i: int in _blocks.size():
		_ev_list.add_child(_make_event_row(i, _blocks[i]))


func _make_event_row(idx: int, block: ClickdevCodeGen.EventBlock) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox  := HBoxContainer.new()
	panel.add_child(hbox)

	var chk := CheckBox.new()
	chk.button_pressed = block.enabled
	chk.toggled.connect(func(v: bool) -> void: block.enabled = v)
	hbox.add_child(chk)

	var lbl := Label.new()
	lbl.text = block.label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	hbox.add_child(lbl)

	var cl := Label.new()
	cl.text = "✅%d" % block.conditions.size()
	cl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	hbox.add_child(cl)

	var al := Label.new()
	al.text = " ⚡%d" % block.actions.size()
	al.add_theme_color_override("font_color", Color(0.45, 0.7, 1.0))
	hbox.add_child(al)

	var eb := Button.new()
	eb.text = "Edit"
	eb.pressed.connect(func() -> void: _show_detail(idx))
	hbox.add_child(eb)

	var db := Button.new()
	db.text = "✕"
	db.pressed.connect(func() -> void: _delete_block(idx))
	hbox.add_child(db)

	return panel


# ═══════════════════════════════════════════════════════════════════
#  DETAIL EDITOR (right panel)
# ═══════════════════════════════════════════════════════════════════

func _clear_detail() -> void:
	for c in _detail_vbox.get_children():
		c.queue_free()


func _show_detail(idx: int) -> void:
	_sel = idx
	var block: ClickdevCodeGen.EventBlock = _blocks[idx]
	_clear_detail()

	# Event name row
	var nr := HBoxContainer.new()
	var nl := Label.new()
	nl.text = "Event name:"
	nr.add_child(nl)
	var ni := LineEdit.new()
	ni.text = block.label
	ni.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ni.text_changed.connect(func(v: String) -> void:
		block.label = v
		_rebuild_list()
	)
	nr.add_child(ni)
	_detail_vbox.add_child(nr)
	_detail_vbox.add_child(HSeparator.new())

	# CONDITIONS header
	var ch := HBoxContainer.new()
	var ct := Label.new()
	ct.text = "✅  CONDITIONS"
	ct.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	ch.add_child(ct)
	var csp := Control.new()
	csp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(csp)
	var ca := Button.new()
	ca.text = "＋ Add Condition"
	ca.pressed.connect(func() -> void: _open_category_picker("condition", block))
	ch.add_child(ca)
	_detail_vbox.add_child(ch)

	if block.conditions.is_empty():
		var nc := Label.new()
		nc.text = "  (none — runs every frame)"
		nc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_detail_vbox.add_child(nc)
	else:
		for ci: int in block.conditions.size():
			_detail_vbox.add_child(_make_cond_row(block, ci))

	_detail_vbox.add_child(HSeparator.new())

	# ACTIONS header
	var ah := HBoxContainer.new()
	var at_ := Label.new()
	at_.text = "⚡  ACTIONS"
	at_.add_theme_color_override("font_color", Color(0.45, 0.7, 1.0))
	ah.add_child(at_)
	var asp := Control.new()
	asp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(asp)
	var aa := Button.new()
	aa.text = "＋ Add Action"
	aa.pressed.connect(func() -> void: _open_category_picker("action", block))
	ah.add_child(aa)
	_detail_vbox.add_child(ah)

	if block.actions.is_empty():
		var na := Label.new()
		na.text = "  (no actions)"
		na.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_detail_vbox.add_child(na)
	else:
		for ai: int in block.actions.size():
			_detail_vbox.add_child(_make_act_row(block, ai))


# ── Condition row ─────────────────────────────────────────────────

func _make_cond_row(block: ClickdevCodeGen.EventBlock, ci: int) -> HBoxContainer:
	var cond: ClickdevCodeGen.ConditionBlock = block.conditions[ci]
	var row  := HBoxContainer.new()
	var cat  : Dictionary = ClickdevCodeGen.get_condition_catalogue()

	var lbl := Label.new()
	lbl.text = cat[cond.type]["label"] if cat.has(cond.type) else cond.type
	lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	row.add_child(lbl)

	if cat.has(cond.type):
		var param_list: Array = cat[cond.type]["params"]
		for param: String in param_list:
			var inp := LineEdit.new()
			inp.placeholder_text = param
			inp.text = str(cond.params.get(param, ""))
			inp.custom_minimum_size.x = 72
			inp.text_changed.connect(func(v: String) -> void: cond.params[param] = v)
			row.add_child(inp)

	var neg := CheckBox.new()
	neg.text = "NOT"
	neg.button_pressed = cond.negate
	neg.toggled.connect(func(v: bool) -> void: cond.negate = v)
	row.add_child(neg)

	var del := Button.new()
	del.text = "✕"
	del.pressed.connect(func() -> void:
		block.conditions.remove_at(ci)
		_show_detail(_sel)
	)
	row.add_child(del)
	return row


# ── Action row ────────────────────────────────────────────────────

func _make_act_row(block: ClickdevCodeGen.EventBlock, ai: int) -> HBoxContainer:
	var act : ClickdevCodeGen.ActionBlock = block.actions[ai]
	var row := HBoxContainer.new()
	var cat : Dictionary = ClickdevCodeGen.get_action_catalogue()

	var lbl := Label.new()
	lbl.text = cat[act.type]["label"] if cat.has(act.type) else act.type
	lbl.add_theme_color_override("font_color", Color(0.45, 0.7, 1.0))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	row.add_child(lbl)

	if cat.has(act.type):
		var param_list: Array = cat[act.type]["params"]
		for param: String in param_list:
			var inp := LineEdit.new()
			inp.placeholder_text = param
			inp.text = str(act.params.get(param, ""))
			inp.custom_minimum_size.x = 72
			inp.text_changed.connect(func(v: String) -> void: act.params[param] = v)
			row.add_child(inp)

	var del := Button.new()
	del.text = "✕"
	del.pressed.connect(func() -> void:
		block.actions.remove_at(ai)
		_show_detail(_sel)
	)
	row.add_child(del)
	return row


# ═══════════════════════════════════════════════════════════════════
#  CATEGORY PICKER
# ═══════════════════════════════════════════════════════════════════

func _open_category_picker(kind: String, block: ClickdevCodeGen.EventBlock) -> void:
	_pick_kind  = kind
	_pick_block = block
	_clear_detail()

	var title := Label.new()
	title.text = ("✅  Choose Condition Category" if kind == "condition" else "⚡  Choose Action Category")
	title.add_theme_color_override(
		"font_color",
		Color(0.3, 0.9, 0.5) if kind == "condition" else Color(0.45, 0.7, 1.0)
	)
	_detail_vbox.add_child(title)

	var back := Button.new()
	back.text = "← Back to event"
	back.pressed.connect(func() -> void: _show_detail(_sel))
	_detail_vbox.add_child(back)
	_detail_vbox.add_child(HSeparator.new())

	var cats: Array = (
		ClickdevCodeGen.get_condition_categories()
		if kind == "condition"
		else ClickdevCodeGen.get_action_categories()
	)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	_detail_vbox.add_child(grid)

	for cat: Dictionary in cats:
		var cat_id: String    = cat["id"]
		var cat_lbl: String   = cat["label"]
		var btn := Button.new()
		btn.text = cat_lbl
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Capture cat_id as a typed local so the lambda captures String, not Variant
		var captured_id: String = cat_id
		btn.pressed.connect(
			func() -> void: _open_item_picker(kind, captured_id, block)
		)
		grid.add_child(btn)


func _open_item_picker(
		kind:        String,
		category_id: String,
		block:       ClickdevCodeGen.EventBlock
) -> void:
	_clear_detail()

	# Resolve category label
	var cats: Array = (
		ClickdevCodeGen.get_condition_categories()
		if kind == "condition"
		else ClickdevCodeGen.get_action_categories()
	)
	var cat_label: String = category_id
	for c: Dictionary in cats:
		if c["id"] == category_id:
			cat_label = c["label"]

	var title := Label.new()
	title.text = cat_label
	title.add_theme_color_override(
		"font_color",
		Color(0.3, 0.9, 0.5) if kind == "condition" else Color(0.45, 0.7, 1.0)
	)
	_detail_vbox.add_child(title)

	var back := Button.new()
	back.text = "← Categories"
	back.pressed.connect(func() -> void: _open_category_picker(kind, block))
	_detail_vbox.add_child(back)
	_detail_vbox.add_child(HSeparator.new())

	var catalogue: Dictionary = (
		ClickdevCodeGen.get_condition_catalogue()
		if kind == "condition"
		else ClickdevCodeGen.get_action_catalogue()
	)

	var found := false
	for key: String in catalogue:
		var entry: Dictionary = catalogue[key]
		if entry["category"] != category_id:
			continue
		found = true

		var btn := Button.new()
		btn.text = entry["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Capture key as typed String — avoids GDScript lambda type-inference bug
		var captured_key: String = key
		btn.pressed.connect(
			func() -> void: _pick_item(kind, captured_key, block)
		)
		_detail_vbox.add_child(btn)

	if not found:
		var empty := Label.new()
		empty.text = "  (no items in this category)"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_detail_vbox.add_child(empty)


func _pick_item(kind: String, key: String, block: ClickdevCodeGen.EventBlock) -> void:
	if kind == "condition":
		block.conditions.append(ClickdevCodeGen.ConditionBlock.new(key))
	else:
		block.actions.append(ClickdevCodeGen.ActionBlock.new(key))
	_show_detail(_sel)


# ═══════════════════════════════════════════════════════════════════
#  TOOLBAR ACTIONS
# ═══════════════════════════════════════════════════════════════════

func _on_add_event() -> void:
	if not is_instance_valid(_sheet):
		return
	var block := ClickdevCodeGen.EventBlock.new()
	block.label = "Event %d" % (_blocks.size() + 1)
	_blocks.append(block)
	_rebuild_list()
	_show_detail(_blocks.size() - 1)


func _delete_block(idx: int) -> void:
	_blocks.remove_at(idx)
	_sel = -1
	_rebuild_list()
	_clear_detail()
	var ph := Label.new()
	ph.text = "← Click an event to edit it"
	ph.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	_detail_vbox.add_child(ph)


func _on_save() -> void:
	if not is_instance_valid(_sheet):
		push_warning("[Clickdev] No ClickdevEventSheet selected.")
		return
	var data: Array = []
	for b: ClickdevCodeGen.EventBlock in _blocks:
		data.append(b.to_dict())
	_sheet.save_events(data)
	_status.text = "✅ Saved — %s  (%d events)" % [_sheet.name, _blocks.size()]
	if _code_edit.visible:
		_refresh_code()


func _toggle_code() -> void:
	_code_edit.visible = not _code_edit.visible
	if _code_edit.visible:
		_refresh_code()


func _refresh_code() -> void:
	if is_instance_valid(_sheet) and _sheet.has_method("preview_code"):
		_code_edit.text = _sheet.preview_code()
