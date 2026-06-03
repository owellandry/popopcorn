extends Node

signal equipo_cambiado(id: String)
signal item_usado(id: String)

const ITEM_BATE := "bate"
const DISTANCIA_GOLPE := 2.8

var _items: Dictionary = {ITEM_BATE: true}
var _equipado: String = ""

func _ready() -> void:
	_equipar(ITEM_BATE)

func tiene_item(id: String) -> bool:
	return _items.get(id, false)

func item_equipado() -> String:
	return _equipado

func equipar_bate() -> void:
	if tiene_item(ITEM_BATE):
		_equipar(ITEM_BATE)

func _equipar(id: String) -> void:
	_equipado = id
	equipo_cambiado.emit(id)

func intentar_golpear(camara: Camera3D) -> bool:
	if _equipado != ITEM_BATE or camara == null:
		return false
	var origen := camara.global_position
	var dir := -camara.global_transform.basis.z
	var fin := origen + dir * DISTANCIA_GOLPE
	var space := camara.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origen, fin)
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador is CollisionObject3D:
		query.exclude = [(jugador as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return false
	var n: Node = hit.collider
	while n:
		if n.is_in_group("visitante") and n.has_method("recibir_golpe_bate"):
			n.recibir_golpe_bate(origen)
			item_usado.emit(ITEM_BATE)
			return true
		n = n.get_parent()
	return false

func obtener_texto_hud() -> String:
	if _equipado == ITEM_BATE:
		return "Bate [Clic izq. / R]"
	return ""