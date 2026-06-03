extends Control

const BRICK_DATA = [
	{"letter": "C", "body": Color("f04545"), "stud": Color("b81c1c")},
	{"letter": "U", "body": Color("1f40b0"), "stud": Color("172e80")},
	{"letter": "B", "body": Color("fabe23"), "stud": Color("d99709")},
	{"letter": "Y", "body": Color("0fb884"), "stud": Color("078057")},
	{"letter": "T", "body": Color("8d5cf5"), "stud": Color("5c21b8")}
]

var _done := false
var _brick_nodes: Array[Control] = []
var _pill: PanelContainer
var _skip_hint: Label
var _main_tween: Tween

func _ready() -> void:
	# Build the background
	var bg = ColorRect.new()
	bg.color = Color("3a7bf5")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)
	
	# Bricks horizontal layout
	var brick_row = HBoxContainer.new()
	brick_row.add_theme_constant_override("separation", 0)
	vbox.add_child(brick_row)
	
	# Load font
	var font = load("res://assets/fonts/TitanOne-Regular.ttf")
	
	# Build bricks
	for data in BRICK_DATA:
		var brick_wrap = Control.new()
		brick_wrap.custom_minimum_size = Vector2(100, 112)
		brick_wrap.pivot_offset = Vector2(50, 112)
		brick_wrap.scale = Vector2(1, 0)
		brick_wrap.modulate.a = 0.0
		brick_row.add_child(brick_wrap)
		_brick_nodes.append(brick_wrap)
		
		# Inner layout
		var vbox_brick = VBoxContainer.new()
		vbox_brick.add_theme_constant_override("separation", 0)
		vbox_brick.set_anchors_preset(Control.PRESET_FULL_RECT)
		brick_wrap.add_child(vbox_brick)
		
		# Studs
		var stud_margin = MarginContainer.new()
		stud_margin.add_theme_constant_override("margin_left", 16)
		stud_margin.add_theme_constant_override("margin_right", 16)
		vbox_brick.add_child(stud_margin)
		
		var stud_row = HBoxContainer.new()
		stud_row.add_theme_constant_override("separation", 12)
		stud_margin.add_child(stud_row)
		
		# Create 2 studs
		for i in range(2):
			var stud = Panel.new()
			stud.custom_minimum_size = Vector2(24, 12)
			
			var stud_style = StyleBoxFlat.new()
			stud_style.bg_color = data["stud"]
			stud_style.border_width_left = 2
			stud_style.border_width_top = 2
			stud_style.border_width_right = 2
			stud_style.border_width_bottom = 2
			stud_style.border_color = Color.BLACK
			stud_style.corner_radius_top_left = 4
			stud_style.corner_radius_top_right = 4
			stud_style.corner_detail = 4
			stud.add_theme_stylebox_override("panel", stud_style)
			stud_row.add_child(stud)
			
		# Brick body
		var body = PanelContainer.new()
		body.custom_minimum_size = Vector2(100, 100)
		
		var body_style = StyleBoxFlat.new()
		body_style.bg_color = data["body"]
		body_style.border_width_left = 3
		body_style.border_width_top = 3
		body_style.border_width_right = 3
		body_style.border_width_bottom = 3
		body_style.border_color = Color.BLACK
		body_style.corner_radius_top_left = 2
		body_style.corner_radius_top_right = 2
		body_style.corner_radius_bottom_right = 2
		body_style.corner_radius_bottom_left = 2
		body_style.corner_detail = 4
		body_style.shadow_color = Color(0, 0, 0, 0.3)
		body_style.shadow_offset = Vector2(4, 4)
		body_style.shadow_size = 0
		body.add_theme_stylebox_override("panel", body_style)
		vbox_brick.add_child(body)
		
		# Letter
		var letter_label = Label.new()
		letter_label.text = data["letter"]
		letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Label settings/overrides
		if font:
			letter_label.add_theme_font_override("font", font)
		letter_label.add_theme_font_size_override("font_size", 64)
		letter_label.add_theme_color_override("font_color", Color.WHITE)
		letter_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
		letter_label.add_theme_constant_override("shadow_offset_x", 2)
		letter_label.add_theme_constant_override("shadow_offset_y", 2)
		body.add_child(letter_label)
		
	# Build Pill Wrapper
	var pill_wrap = Control.new()
	pill_wrap.custom_minimum_size = Vector2(300, 48)
	vbox.add_child(pill_wrap)
	
	# Build Pill Panel
	_pill = PanelContainer.new()
	_pill.set_anchors_preset(Control.PRESET_CENTER)
	_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pill.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pill.modulate.a = 0.0
	pill_wrap.add_child(_pill)
	
	var pill_style = StyleBoxFlat.new()
	pill_style.bg_color = Color.WHITE
	pill_style.border_width_left = 3
	pill_style.border_width_top = 3
	pill_style.border_width_right = 3
	pill_style.border_width_bottom = 3
	pill_style.border_color = Color.BLACK
	pill_style.corner_radius_top_left = 24
	pill_style.corner_radius_top_right = 24
	pill_style.corner_radius_bottom_right = 24
	pill_style.corner_radius_bottom_left = 24
	pill_style.content_margin_left = 32
	pill_style.content_margin_right = 32
	pill_style.content_margin_top = 10
	pill_style.content_margin_bottom = 10
	pill_style.shadow_color = Color(0, 0, 0, 0.25)
	pill_style.shadow_offset = Vector2(4, 4)
	pill_style.shadow_size = 0
	_pill.add_theme_stylebox_override("panel", pill_style)
	
	var pill_label = Label.new()
	pill_label.text = "S T U D I O"
	pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		pill_label.add_theme_font_override("font", font)
	pill_label.add_theme_font_size_override("font_size", 18)
	pill_label.add_theme_color_override("font_color", Color.BLACK)
	_pill.add_child(pill_label)
	
	# Skip Hint Label
	_skip_hint = Label.new()
	_skip_hint.text = "Clic o tecla para saltar"
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	if font:
		_skip_hint.add_theme_font_override("font", font)
	_skip_hint.add_theme_font_size_override("font_size", 12)
	_skip_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	add_child(_skip_hint)
	
	# Wait for layout to settle, so we can position the pill correctly for sliding
	await get_tree().process_frame
	
	# Adjust Skip Hint position slightly upwards
	_skip_hint.position.y -= 36
	
	# Set up Pill start position (offset by 8px vertically)
	var original_pill_y = _pill.position.y
	_pill.position.y = original_pill_y + 8
	
	# Start animation
	_run_animation(original_pill_y)

func _run_animation(original_pill_y: float) -> void:
	_main_tween = create_tween()
	# We want parallel tweens for staggered bricks
	_main_tween.set_parallel(true)
	
	# Animating bricks
	for i in range(_brick_nodes.size()):
		var brick = _brick_nodes[i]
		var delay = 0.5 + i * 0.12
		
		# Scale Y animation with Back ease-out (bounce)
		var t_scale = _main_tween.tween_property(brick, "scale:y", 1.0, 0.35)
		t_scale.set_trans(Tween.TRANS_BACK)
		t_scale.set_ease(Tween.EASE_OUT)
		t_scale.set_delay(delay)
		
		# Modulate alpha
		var t_alpha = _main_tween.tween_property(brick, "modulate:a", 1.0, 0.21)
		t_alpha.set_trans(Tween.TRANS_SINE)
		t_alpha.set_ease(Tween.EASE_OUT)
		t_alpha.set_delay(delay)
		
	# Animating Pill
	var pill_delay = 0.5 + 5 * 0.12 + 0.08 # 1.18 seconds
	
	var t_pill_alpha = _main_tween.tween_property(_pill, "modulate:a", 1.0, 0.4)
	t_pill_alpha.set_delay(pill_delay)
	
	var t_pill_pos = _main_tween.tween_property(_pill, "position:y", original_pill_y, 0.4)
	t_pill_pos.set_trans(Tween.TRANS_SINE)
	t_pill_pos.set_ease(Tween.EASE_OUT)
	t_pill_pos.set_delay(pill_delay)
	
	# Wait for all animations in this tween to finish
	_main_tween.set_parallel(false) # Wait for previous animations to finish before running next step
	
	# Hold for 2.2 seconds
	_main_tween.tween_interval(2.2)
	
	# Remove fade out, go directly to menu using transition
	
	await _main_tween.finished
	_go_to_menu()

func _input(event: InputEvent) -> void:
	if _done:
		return
		
	# Skip on mouse click, screen touch or any key press
	var is_click = event is InputEventMouseButton and event.pressed
	var is_key = event is InputEventKey and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_key or is_touch:
		_skip()

func _skip() -> void:
	_done = true
	if _main_tween:
		_main_tween.kill()
		
	_transition_to_menu_fast()

func _transition_to_menu_fast() -> void:
	if has_node("/root/Transicion"):
		var trans = get_node("/root/Transicion")
		trans.transicionar("res://scenes/menu/menu_principal.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")

func _go_to_menu() -> void:
	if _done:
		return
	_done = true
	
	# Transition to the main menu directly without fading to transparent.
	if has_node("/root/Transicion"):
		var trans = get_node("/root/Transicion")
		trans.transicionar("res://scenes/menu/menu_principal.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/menu_principal.tscn")
