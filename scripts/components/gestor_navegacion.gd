@tool
extends NavigationRegion3D

signal navegacion_lista

func _ready() -> void:
	if Engine.is_editor_hint():
		await get_tree().process_frame
		bake_navigation_mesh(false)
		print("NavigationMesh horneado correctamente. Guarda la escena (Ctrl+S) para persistir el navmesh.")
		return
	await get_tree().process_frame
	navegacion_lista.emit()
