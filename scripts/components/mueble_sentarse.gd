extends Node3D
class_name MuebleSentarse

const UtilAsientoScript := preload("res://scripts/components/util_asiento.gd")

## Muebles y butacas: cada silla/marker es un asiento (mesa = una silla libre por NPC; sofá/cine igual).
@export var tipo_mueble: String = "sofa"
@export var max_personas: int = 2
@export var contenedor_asientos: NodePath
@export var altura_pies: float = 0.0
@export var avance_asiento: float = 0.07

class SlotAsiento:
	var nodo: Node3D
	var visitante: Node3D = null
	var pose: Dictionary = {}

var _slots: Array[SlotAsiento] = []

func _ready() -> void:
	add_to_group("mueble_sentarse")
	call_deferred("_configurar")

func _configurar() -> void:
	_inicializar_asientos()
	if tipo_mueble == "mesa":
		max_personas = maxi(1, _slots.size())
	elif tipo_mueble == "cine":
		max_personas = maxi(1, _slots.size())

func _nodo_fuente() -> Node3D:
	if not contenedor_asientos.is_empty():
		var n := get_node_or_null(contenedor_asientos)
		if n is Node3D:
			return n as Node3D
	if get_parent() is Node3D and name == "_MuebleSentarse":
		return get_parent() as Node3D
	return self

func _inicializar_asientos() -> void:
	_slots.clear()
	var fuente := _nodo_fuente()
	if fuente == null:
		return
	if tipo_mueble == "mesa":
		_generar_markers_mesa(fuente)
	_recolectar_desde_contenedor(fuente.get_node_or_null("Asientos"))
	if _slots.is_empty():
		_recolectar_sillas_en_arbol(fuente)
	if _slots.is_empty():
		push_warning("[MuebleSentarse] Sin asientos en: %s" % fuente.get_path())

func _recolectar_desde_contenedor(contenedor: Node) -> void:
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		if hijo is Node3D:
			_agregar_slot(hijo as Node3D)

func _recolectar_sillas_en_arbol(raiz: Node3D) -> void:
	var candidatos: Array[Node3D] = []
	_buscar_nodos_asiento(raiz, candidatos)
	candidatos.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return str(a.get_path()) < str(b.get_path())
	)
	for n in candidatos:
		_agregar_slot(n)

func _buscar_nodos_asiento(nodo: Node, out: Array[Node3D]) -> void:
	if nodo is Node3D:
		var n3 := nodo as Node3D
		var nombre := n3.name
		if nombre.begins_with("Asiento"):
			out.append(n3)
			return
		if nombre.begins_with("Silla") and nombre.ends_with("Body"):
			out.append(n3)
			return
		if nombre.begins_with("Silla") and not nombre.contains("Col"):
			var padre := nodo.get_parent()
			if padre and (padre.name == "Butacas" or padre.name.begins_with("Butacas")):
				out.append(n3)
				return
			if padre and padre.name.ends_with("Body"):
				pass
			else:
				out.append(n3)
				return
	for hijo in nodo.get_children():
		if hijo.name.begins_with("Col"):
			continue
		_buscar_nodos_asiento(hijo, out)

func _generar_markers_mesa(fuente: Node3D) -> void:
	var contenedor := fuente.get_node_or_null("Asientos")
	if contenedor == null:
		contenedor = Node3D.new()
		contenedor.name = "Asientos"
		fuente.add_child(contenedor)
	var tiene_markers := false
	for hijo in contenedor.get_children():
		if hijo is Marker3D:
			tiene_markers = true
			break
	if tiene_markers:
		return
	var cuerpos: Array[Node3D] = []
	_buscar_nodos_asiento(fuente, cuerpos)
	for body in cuerpos:
		if not body.name.ends_with("Body"):
			continue
		var marker := Marker3D.new()
		marker.name = "Asiento_%s" % body.name
		contenedor.add_child(marker)
		var pose: Dictionary = UtilAsientoScript.pose_desde_nodo(body, altura_pies, avance_asiento)
		marker.global_position = pose.get("posicion", body.global_position)
		marker.global_rotation = pose.get("rotacion", body.global_rotation)

func _agregar_slot(nodo: Node3D) -> void:
	for s in _slots:
		if s.nodo == nodo:
			return
	var slot := SlotAsiento.new()
	slot.nodo = nodo
	slot.pose = UtilAsientoScript.pose_desde_nodo(nodo, altura_pies, avance_asiento)
	_slots.append(slot)

func esta_ocupada() -> bool:
	_limpiar_invalidos()
	return cupos_libres() <= 0

func cupos_libres() -> int:
	return cupos_libres_para(1)

func cupos_libres_para(cantidad: int) -> int:
	_limpiar_invalidos()
	var libres_sillas := _contar_slots_libres()
	if cantidad >= 2 and libres_sillas < cantidad:
		return 0
	return mini(libres_sillas, max_personas - _visitantes_activos())

func _contar_slots_libres() -> int:
	var n := 0
	for s in _slots:
		if s.visitante == null:
			n += 1
	return n

func _visitantes_activos() -> int:
	var n := 0
	for s in _slots:
		if s.visitante != null:
			n += 1
	return n

func puede_acomodar(cantidad: int = 1) -> bool:
	return cupos_libres_para(cantidad) >= cantidad

func asignar_pareja(visitante_a: Node3D, visitante_b: Node3D) -> Dictionary:
	_limpiar_invalidos()
	if not puede_acomodar(2):
		return {}
	var pose_a := _asignar_en_slot_libre(visitante_a)
	if pose_a.is_empty():
		return {}
	var pose_b := _asignar_en_slot_libre(visitante_b)
	if pose_b.is_empty():
		liberar_visitante(visitante_a)
		return {}
	return {"a": pose_a, "b": pose_b}

func _asignar_en_slot_libre(visitante: Node3D) -> Dictionary:
	var indice := _elegir_slot_libre()
	if indice < 0:
		return {}
	var slot := _slots[indice]
	slot.visitante = visitante
	if slot.nodo is Marker3D:
		return slot.pose.duplicate()
	return UtilAsientoScript.pose_desde_nodo(slot.nodo, altura_pies, avance_asiento)

func asignar_visitante(visitante: Node3D) -> Dictionary:
	_limpiar_invalidos()
	if not puede_acomodar(1):
		return {}
	var indice := _elegir_slot_libre()
	if indice < 0:
		return {}
	var slot := _slots[indice]
	slot.visitante = visitante
	if slot.nodo is Marker3D:
		return slot.pose.duplicate()
	return UtilAsientoScript.pose_desde_nodo(slot.nodo, altura_pies, avance_asiento)

func liberar_visitante(visitante: Node3D) -> void:
	for s in _slots:
		if s.visitante == visitante:
			s.visitante = null

func _elegir_slot_libre() -> int:
	var libres: Array[int] = []
	for i in range(_slots.size()):
		if _slots[i].visitante == null:
			libres.append(i)
	if libres.is_empty():
		return -1
	if tipo_mueble == "mesa":
		return libres[randi() % libres.size()]
	return libres[0]

func obtener_pose_slot(visitante: Node3D) -> Dictionary:
	for s in _slots:
		if s.visitante == visitante:
			return s.pose.duplicate()
	return {}

func _limpiar_invalidos() -> void:
	for s in _slots:
		if s.visitante != null and not is_instance_valid(s.visitante):
			s.visitante = null

static func buscar_con_cupos(cantidad: int, arbol: SceneTree, filtro_tipo: String = "") -> MuebleSentarse:
	var opciones: Array[MuebleSentarse] = []
	for n in arbol.get_nodes_in_group("mueble_sentarse"):
		if n is MuebleSentarse:
			var m := n as MuebleSentarse
			if not filtro_tipo.is_empty() and m.tipo_mueble != filtro_tipo:
				continue
			if m.puede_acomodar(cantidad):
				opciones.append(m)
	if opciones.is_empty():
		return null
	return opciones.pick_random()

static func buscar_sala_cine(arbol: SceneTree, numero: int) -> MuebleSentarse:
	for n in arbol.get_nodes_in_group("sala_cine"):
		if n.get("numero_sala") == numero:
			return _mueble_butacas_de_sala(n)
	for m in arbol.get_nodes_in_group("mueble_sentarse"):
		if m is MuebleSentarse and (m as MuebleSentarse).tipo_mueble == "cine":
			var sala: Node = m._nodo_fuente().get_parent() if m.name == "_MuebleSentarse" else m
			if sala and sala.get("numero_sala") == numero:
				return m as MuebleSentarse
	return null

static func _mueble_butacas_de_sala(sala: Node) -> MuebleSentarse:
	var aux := sala.get_node_or_null("_MuebleSentarse")
	if aux is MuebleSentarse:
		return aux as MuebleSentarse
	var butacas := sala.get_node_or_null("Butacas")
	if butacas is MuebleSentarse:
		return butacas as MuebleSentarse
	return null
