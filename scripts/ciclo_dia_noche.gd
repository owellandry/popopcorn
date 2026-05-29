extends DirectionalLight3D

func _ready():
	# Noche - sol apagado
	rotation_degrees = Vector3(-90, 0, 0)
	light_energy = 0.0
