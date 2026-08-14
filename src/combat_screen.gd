extends Control

var model := CombatModel.new()
var enemy_health_bar: Dictionary
var enemy_timer_bar: Dictionary
var player_health_bar: Dictionary
var player_timer_bar: Dictionary
var enemy_name_label: Label
var status_labels: Dictionary = {}
var equipment_labels: Dictionary = {}
var draw_label: Label
var log_label: Label
var cards: HBoxContainer
var overlay: ColorRect
var result_label: Label
var cards_signature := ""

func _ready() -> void:
	_build_ui()
	model.state_changed.connect(_refresh)
	model.combat_finished.connect(_on_finished)
	model.start()

func _process(delta: float) -> void:
	model.advance(delta)
	_refresh()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("0b0a14")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)

	# Enemy sprite (centre stage).
	var enemy_art := TextureRect.new()
	enemy_art.texture = load("res://assets/enemy_corrupted_vine.png")
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place_abs(layer, enemy_art, 450, 152, 380, 214)

	# Element icon row (top-left).
	var icons := ["blade", "fire", "guard", "arcane", "nature"]
	for i in icons.size():
		var t := TextureRect.new()
		t.texture = load("res://assets/icons/%s.png" % icons[i])
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		_place_abs(layer, t, 14 + i * 52, 12, 46, 46)

	# Status counters (top-right).
	_build_status_counters(layer)

	# Enemy name + bars (top-centre).
	enemy_name_label = _label(26)
	enemy_name_label.add_theme_color_override("font_color", Color("c58be0"))
	_place_abs(layer, enemy_name_label, 340, 4, 600, 32)
	enemy_health_bar = _make_stat_bar(HP_FRAME, HP_FILL, HP_INNER, HEALTH_BAR_SIZE, true)
	_place_abs(layer, enemy_health_bar.root, 640 - HEALTH_BAR_SIZE.x / 2, 42, HEALTH_BAR_SIZE.x, HEALTH_BAR_SIZE.y)
	enemy_timer_bar = _make_stat_bar(TIMER_FRAME, TIMER_FILL, TIMER_INNER, TIMER_BAR_SIZE, false)
	_place_abs(layer, enemy_timer_bar.root, 640 - TIMER_BAR_SIZE.x / 2, 100, TIMER_BAR_SIZE.x, TIMER_BAR_SIZE.y)

	# Card hand (lower-left band).
	cards = HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_BEGIN
	cards.add_theme_constant_override("separation", 16)
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_abs(layer, cards, 196, 372, 540, CARD_SIZE.y)

	# Equipment slots (right of hand).
	_build_equipment_grid(layer)

	# Bottom-left controls.
	var end_btn := _ui_button("END TURN", Color("29406a"), Color("6ea0e0"))
	end_btn.pressed.connect(func(): model.player_progress = 0.0)
	_place_abs(layer, end_btn, 14, 590, 188, 46)
	var menu_btn := _ui_button("MENU", Color("1a2233"), Color("8497b5"))
	_place_abs(layer, menu_btn, 14, 642, 188, 38)

	# Player portrait + level.
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/icons/portrait.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_place_abs(layer, portrait, 212, 588, 76, 92)
	var lvl := _label(15)
	lvl.text = "5"
	lvl.add_theme_color_override("font_color", Color("f4ecd6"))
	var lvl_bg := StyleBoxFlat.new(); lvl_bg.bg_color = Color("101a2c"); lvl_bg.border_color = Color("4d8fd6"); lvl_bg.set_border_width_all(2); lvl_bg.set_corner_radius_all(4)
	lvl.add_theme_stylebox_override("normal", lvl_bg)
	_place_abs(layer, lvl, 268, 654, 28, 26)

	# Player bars (bottom-centre).
	player_health_bar = _make_stat_bar(HP_FRAME, HP_FILL, HP_INNER, HEALTH_BAR_SIZE, true)
	_place_abs(layer, player_health_bar.root, 306, 586, HEALTH_BAR_SIZE.x, HEALTH_BAR_SIZE.y)
	player_timer_bar = _make_stat_bar(TIMER_FRAME, TIMER_FILL, TIMER_INNER, TIMER_BAR_SIZE, false)
	_place_abs(layer, player_timer_bar.root, 306, 644, TIMER_BAR_SIZE.x, TIMER_BAR_SIZE.y)

	# Draw pile (bottom-right).
	var draw_btn := _ui_button("", Color("2a1c3e"), Color("a06ad4"))
	_place_abs(layer, draw_btn, 992, 600, 248, 66)
	draw_label = _label(20)
	draw_label.add_theme_color_override("font_color", Color("e8dcff"))
	draw_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_abs(layer, draw_label, 992, 600, 248, 66)

	# Battle log (subtle, bottom-centre).
	log_label = _label(14)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_color_override("font_color", Color("7f8ba6"))
	_place_abs(layer, log_label, 306, 696, HEALTH_BAR_SIZE.x, 22)

	overlay = ColorRect.new(); overlay.color = Color(0.02, 0.03, 0.06, 0.9); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.hide(); add_child(overlay)
	var result_box := VBoxContainer.new(); result_box.set_anchors_preset(Control.PRESET_CENTER); result_box.position = Vector2(-150, -70); result_box.size = Vector2(300, 140); overlay.add_child(result_box)
	result_label = _label(36); result_box.add_child(result_label)
	var again := Button.new(); again.text = "DELVE AGAIN"; again.custom_minimum_size.y = 48; again.pressed.connect(func(): overlay.hide(); model.start()); result_box.add_child(again)

func _refresh() -> void:
	_update_bar(enemy_health_bar, float(model.enemy_health) / model.enemy_max_health, "THE WARDEN    %d / %d" % [model.enemy_health, model.enemy_max_health])
	_update_bar(player_health_bar, float(model.player_health) / model.player_max_health, "%d / %d HP    •    %d BLOCK" % [model.player_health, model.player_max_health, model.player_block])
	_update_bar(enemy_timer_bar, model.enemy_progress / CombatModel.TURN_THRESHOLD, "")
	_update_bar(player_timer_bar, model.player_progress / CombatModel.TURN_THRESHOLD, "")
	enemy_name_label.text = "✦  THE WARDEN  ✦"
	status_labels["shield"].text = "%d" % model.get_stat("defence")
	status_labels["heart"].text = "%d" % model.get_stat("attack")
	status_labels["plus"].text = "%d" % model.get_stat("power")
	status_labels["wing"].text = "%d" % model.get_stat("speed")
	draw_label.text = "DRAW   ✦ %d" % model.draw_pile.size()
	for slot: String in equipment_labels:
		var item: Dictionary = model.equipment[slot]
		equipment_labels[slot].text = _equipment_text(slot, item)
	log_label.text = model.battle_log
	_refresh_abilities()

func _place_abs(parent: Control, node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.custom_minimum_size = Vector2(w, h)
	node.size = Vector2(w, h)
	parent.add_child(node)

func _ui_button(text: String, bg: Color, border: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("f0ead8"))
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg.lightened(0.12) if state == "hover" else bg
		sb.border_color = border
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_top = 6; sb.content_margin_bottom = 6
		b.add_theme_stylebox_override(state, sb)
	return b

func _build_status_counters(layer: Control) -> void:
	var order := [["shield", "st_shield"], ["heart", "st_heart"], ["plus", "st_plus"], ["wing", "st_wing"]]
	var x := 962.0
	for pair in order:
		var icon := TextureRect.new()
		icon.texture = load("res://assets/icons/%s.png" % pair[1])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place_abs(layer, icon, x, 12, 30, 30)
		var num := _label(18)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		num.add_theme_color_override("font_color", Color("f4ecd6"))
		_place_abs(layer, num, x + 32, 14, 34, 26)
		status_labels[pair[0]] = num
		x += 66
	var gear := TextureRect.new()
	gear.texture = load("res://assets/icons/gear.png")
	gear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place_abs(layer, gear, 1234, 10, 34, 34)

func _build_equipment_grid(layer: Control) -> void:
	var slots := ["head", "chest", "legs", "boots", "left_hand", "right_hand"]
	for i in slots.size():
		var col := i % 3
		var row := i / 3
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("15122a")
		style.border_color = Color("5a3f7a")
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8; style.content_margin_right = 8
		panel.add_theme_stylebox_override("panel", style)
		var label := _label(10)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(label)
		_place_abs(layer, panel, 812 + col * 128, 372 + row * 108, 118, 98)
		equipment_labels[slots[i]] = label

func _equipment_text(slot: String, item: Dictionary) -> String:
	var heading := slot.replace("_", " ").to_upper()
	if item.is_empty():
		return "%s\n— EMPTY —" % heading
	var bonuses: Array[String] = []
	for stat in ["attack", "power", "defence", "speed"]:
		if item.get(stat, 0) != 0:
			bonuses.append("+%d %s" % [item[stat], stat.to_upper()])
	return "%s\n%s  %s" % [heading, item.name, " ".join(bonuses)]

func _refresh_abilities() -> void:
	var next_signature := model.state + ":" + JSON.stringify(model.choices)
	if next_signature == cards_signature:
		return
	cards_signature = next_signature
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	if model.state == "PLAYER_TURN":
		for i in model.choices.size():
			cards.add_child(_ability_card(model.choices[i], i))
	else:
		var waiting := _label(17); waiting.text = "Turn gauges are filling…"; waiting.modulate = Color("8190a8"); cards.add_child(waiting)

# --- Card look & feel -------------------------------------------------------
const CARD_SIZE := Vector2(146, 210)
# Inner panel rects as fractions of the frame, measured from assets/card_frame.png.
const ART_RECT := Rect2(0.0996, 0.0658, 0.7984, 0.3346)   # top art window
const TITLE_RECT := Rect2(0.1104, 0.4121, 0.7783, 0.0781) # centre name bar
const DESC_RECT := Rect2(0.0996, 0.5052, 0.7984, 0.3542)  # description panel
const BADGE_RECT := Rect2(0.1553, 0.8750, 0.6738, 0.0632) # bottom element bar

func _element_color(type: String) -> Color:
	match type:
		"BLADE": return Color("d4515d")
		"FIRE": return Color("e08a3c")
		"GUARD": return Color("4d8fd6")
		"ARCANE": return Color("a06ad4")
		"NATURE": return Color("5bb85b")
	return Color("c4d0e8")

func _ability_card(ability: Dictionary, index: int) -> Button:
	var active: bool = model.chain_is_active(ability)
	var accent := _element_color(ability.type)

	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.clip_contents = false
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		card.add_theme_stylebox_override(s, empty)

	# Frame image fills the whole card.
	var frame := TextureRect.new()
	frame.texture = load("res://assets/card_frame.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)

	# Placeholder art in the top window.
	var art := TextureRect.new()
	var art_path := "res://assets/art/%s.png" % ability.name.to_lower().replace(" ", "_")
	if ResourceLoader.exists(art_path):
		art.texture = load(art_path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	_place(art, ART_RECT)
	card.add_child(art)

	# Title bar.
	var title := Label.new()
	title.text = ability.name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("f0e4c4"))
	_place(title, TITLE_RECT)
	card.add_child(title)

	# Description panel (rich text so chain effects can be tinted).
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.scroll_active = false
	desc.fit_content = false
	desc.add_theme_font_size_override("normal_font_size", 11)
	desc.text = _card_description(ability, accent, active)
	_place(desc, DESC_RECT)
	card.add_child(desc)

	# Element badge along the bottom bar.
	var badge := Label.new()
	badge.text = str(ability.type)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", accent)
	_place(badge, BADGE_RECT)
	card.add_child(badge)

	# Chain-ready highlight.
	if active:
		card.modulate = Color("ffe9a8")
		var glow := Label.new()
		glow.text = "★ CHAIN READY"
		glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glow.add_theme_font_size_override("font_size", 11)
		glow.add_theme_color_override("font_color", Color("ffd85a"))
		glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		glow.offset_top = 6
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(glow)

	card.mouse_entered.connect(func(): card.modulate = (Color("fff2c8") if active else Color("cfe0ff")))
	card.mouse_exited.connect(func(): card.modulate = (Color("ffe9a8") if active else Color.WHITE))
	card.pressed.connect(func(): model.play_choice(index))
	return card

func _card_description(ability: Dictionary, accent: Color, active: bool) -> String:
	var lines: Array[String] = []
	var effects := model.ability_effects(ability, false)
	lines.append(model._effect_summary(effects.damage, effects.block, effects.heal).capitalize())
	lines.append("[color=#8fa3bf]Scales with %s[/color]" % str(ability.scales_with).capitalize())
	if ability.chain_type != "":
		var tag := "CHAIN: %s" % ability.chain_type
		lines.append("[color=#%s]%s[/color]" % [accent.to_html(false), tag])
		lines.append(model._effect_summary(ability.chain_damage, ability.chain_block, ability.chain_heal).capitalize())
	var body := "\n".join(lines)
	return "[center]%s[/center]" % body

func _place(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.position.x + rect.size.x
	node.anchor_bottom = rect.position.y + rect.size.y
	node.offset_left = 0; node.offset_top = 0; node.offset_right = 0; node.offset_bottom = 0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _label(size: int) -> Label:
	var label := Label.new(); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", size); return label

# --- Art-based stat bars (health frame + fill, turn timer + fill) ------------
const HP_FRAME := "res://assets/hp_frame.png"
const HP_FILL := "res://assets/hp_fill.png"
const TIMER_FRAME := "res://assets/timer_frame.png"
const TIMER_FILL := "res://assets/timer_fill.png"
# Inner fill channel of each frame, measured from the cropped sprites.
const HP_INNER := Rect2(0.1489, 0.0696, 0.8223, 0.8797)
const TIMER_INNER := Rect2(0.1340, 0.0652, 0.8482, 0.9293)
const HEALTH_BAR_SIZE := Vector2(470, 53)
const TIMER_BAR_SIZE := Vector2(360, 47)

func _make_stat_bar(frame_path: String, fill_path: String, inner: Rect2, bar_size: Vector2, with_label: bool) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = bar_size
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var frame := TextureRect.new()
	frame.texture = load(frame_path)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)

	var region := Rect2(inner.position.x * bar_size.x, inner.position.y * bar_size.y, inner.size.x * bar_size.x, inner.size.y * bar_size.y)
	var clip := Control.new()
	clip.position = region.position
	clip.size = region.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := TextureRect.new()
	fill.texture = load(fill_path)
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.position = Vector2.ZERO
	fill.size = region.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)
	root.add_child(clip)

	var label: Label = null
	if with_label:
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color("f6efdb"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.position = region.position
		label.size = region.size
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(label)

	return {"root": root, "clip": clip, "region": region, "label": label}

func _update_bar(bar: Dictionary, pct: float, text: String) -> void:
	if bar.is_empty():
		return
	pct = clampf(pct, 0.0, 1.0)
	var region: Rect2 = bar.region
	bar.clip.size = Vector2(region.size.x * pct, region.size.y)
	if bar.label != null:
		bar.label.text = text

func _on_finished(result: String) -> void:
	result_label.text = result; result_label.modulate = Color("e7c778") if result == "VICTORY" else Color("ef6a74"); overlay.show()
