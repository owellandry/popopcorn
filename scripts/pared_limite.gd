extends StaticBody3D

@onready var area: Area3D = $Area3D

var _showing := false
const DISPLAY_TIME := 5.0

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	$CanvasLayer.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador") and not _showing:
		_showing = true
		$CanvasLayer.visible = true
		await get_tree().create_timer(DISPLAY_TIME).timeout
		$CanvasLayer.visible = false
		_showing = false
