extends Node3D

@export var numero_sala: int = 1
@export var pantalla: Node3D = null

const MuebleSentarseScript := preload("res://scripts/components/mueble_sentarse.gd")

func _ready() -> void:
	add_to_group("sala_cine")
	_configurar_butacas()

func _configurar_butacas() -> void:
	var butacas := get_node_or_null("Butacas")
	if butacas == null:
		return
	if butacas is MuebleSentarse:
		(butacas as MuebleSentarse).tipo_mueble = "cine"
		return
	if butacas.get_node_or_null("_MuebleSentarse"):
		return
	var aux := Node3D.new()
	aux.name = "_MuebleSentarse"
	aux.set_script(MuebleSentarseScript)
	butacas.add_child(aux)
	var ms := aux as MuebleSentarse
	ms.contenedor_asientos = NodePath("..")
	ms.tipo_mueble = "cine"
	ms.avance_asiento = 0.05
	ms.call_deferred("_configurar")

func asignar_asiento(visitante: CharacterBody3D) -> bool:
	var mueble := MuebleSentarse.buscar_sala_cine(get_tree(), numero_sala)
	if mueble == null:
		mueble = _mueble_local()
	if mueble == null or not mueble.puede_acomodar(1):
		return false
	var pose := mueble.asignar_visitante(visitante)
	if pose.is_empty():
		return false
	if visitante.has_method("sentarse_en_pose"):
		visitante.sentarse_en_pose(pose, mueble)
	elif visitante.has_method("sentarse"):
		visitante.sentarse(pose)
	return true

func _mueble_local() -> MuebleSentarse:
	return MuebleSentarse.buscar_sala_cine(get_tree(), numero_sala)