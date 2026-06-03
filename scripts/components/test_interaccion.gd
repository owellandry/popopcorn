extends SceneTree

func _initialize() -> void:
	var hud := preload("res://scenes/ui/hud.tscn").instantiate()
	get_root().add_child(hud)
	await process_frame
	
	var objetivo := Node3D.new()
	get_root().add_child(objetivo)
	
	hud.set("_current_interactive", objetivo)
	
	_assert_true(hud.puede_interactuar(objetivo, true), "Debe permitir interacción si está en rango y mirando")
	_assert_false(hud.puede_interactuar(objetivo, false), "No debe permitir interacción si no está en rango")
	
	var otro := Node3D.new()
	get_root().add_child(otro)
	_assert_false(hud.puede_interactuar(otro, true), "No debe permitir interacción si está en rango pero no mirando")
	
	print("OK:test_interaccion")
	quit(0)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)

func _assert_false(value: bool, message: String) -> void:
	if value:
		push_error(message)
		quit(1)
