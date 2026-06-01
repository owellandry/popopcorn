extends CharacterBody3D

@export var color: Color = Color(0.8, 0.2, 0.2, 1)
@export var nombre_pelicula: String = "La Aventura Espacial"
@export var sala_asignada: int = 1

var estado: String = "espera"
var asiento: Node3D = null

func _ready():
	var mesh = MeshInstance3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 1.8, 0.3)
	
	var colision = CollisionShape3D.new()
	colision.shape = shape
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	
	var mesh_geom = BoxMesh.new()
	mesh_geom.size = Vector3(0.5, 1.8, 0.3)
	mesh_geom.material = material
	
	mesh.mesh = mesh_geom
	add_child(mesh)
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
