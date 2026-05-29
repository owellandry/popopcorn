extends Node3D

@onready var butacas_container = $Butacas

const SILLA_SCENE = preload("res://scenes/decoraciones/silla_cine.tscn")

func _ready() -> void:
	# Limpiar marcadores de posición del editor si existen
	for child in butacas_container.get_children():
		child.queue_free()
		
	# Distribución de butacas:
	# Bloque Izquierdo: X de -6.5 a -1.5, con espaciado de 1.0m (6 columnas)
	# Bloque Derecho: X de 1.5 a 6.5, con espaciado de 1.0m (6 columnas)
	# Filas: Z de -3.5 a 4.0, con espaciado de 1.5m (6 filas)
	
	var x_left = [-6.5, -5.5, -4.5, -3.5, -2.5, -1.5]
	var x_right = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
	var z_rows = [-3.5, -2.0, -0.5, 1.0, 2.5, 4.0]
	
	# Rotación de 180 grados en Y para que miren hacia la pantalla (dirección -Z)
	var rot_basis = Basis(Vector3.UP, PI)
	
	# Generar bloque izquierdo
	for r in range(z_rows.size()):
		var z = z_rows[r]
		for c in range(x_left.size()):
			var x = x_left[c]
			_spawn_chair(x, 0.0, z, rot_basis)
			
	# Generar bloque derecho
	for r in range(z_rows.size()):
		var z = z_rows[r]
		for c in range(x_right.size()):
			var x = x_right[c]
			_spawn_chair(x, 0.0, z, rot_basis)

func _spawn_chair(x: float, y: float, z: float, rot: Basis) -> void:
	var silla = SILLA_SCENE.instantiate()
	silla.transform = Transform3D(rot, Vector3(x, y, z))
	butacas_container.add_child(silla)
