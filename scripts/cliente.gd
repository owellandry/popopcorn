extends CharacterBody3D

@export var color: Color = Color(0.8, 0.2, 0.2, 1)
@export var nombre_pelicula: String = "La Aventura Espacial"
@export var sala_asignada: int = 1

var estado: String = "espera"
var asiento: Node3D = null

func _ready():
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.25
	capsule_shape.height = 1.2
	
	var colision = CollisionShape3D.new()
	colision.shape = capsule_shape
	colision.transform.origin.y = 0.9
	
	var material_cuerpo = StandardMaterial3D.new()
	material_cuerpo.albedo_color = color
	material_cuerpo.roughness = 0.7
	
	var cuerpo = CapsuleMesh.new()
	cuerpo.radius = 0.25
	cuerpo.height = 1.2
	cuerpo.material = material_cuerpo
	
	var mesh_cuerpo = MeshInstance3D.new()
	mesh_cuerpo.mesh = cuerpo
	mesh_cuerpo.transform.origin.y = 0.9
	add_child(mesh_cuerpo)
	
	var cabeza = SphereMesh.new()
	cabeza.radius = 0.15
	cabeza.height = 0.2
	
	var material_cabeza = StandardMaterial3D.new()
	material_cabeza.albedo_color = Color(0.9, 0.75, 0.65)
	cabeza.material = material_cabeza
	
	var mesh_cabeza = MeshInstance3D.new()
	mesh_cabeza.mesh = cabeza
	mesh_cabeza.transform.origin.y = 1.7
	add_child(mesh_cabeza)
	
	add_child(colision)

func hablar():
	# Función para cuando el jugador interactúa con el cliente
	emit_signal("cliente_habla", self, nombre_pelicula)

func ir_a_sala():
	estado = "yendo_sala"

func sentarse(asiento_obj: Node3D):
	estado = "sentado"
	asiento = asiento_obj
	global_position = asiento_obj.global_position
	global_rotation = asiento_obj.global_rotation

func ver_pelicula():
	estado = "viendo_pelicula"

func irse():
	estado = "irse"

signal cliente_habla(cliente: Node3D, pelicula: String)
