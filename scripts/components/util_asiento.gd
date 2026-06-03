class_name UtilAsiento

## Calcula posición/rotación global para sentar un NPC (pies en la superficie del asiento, centrado).
const AVANCE_DEFECTO := 0.07
const ALTURA_PIES_DEFECTO := 0.0

static func pose_desde_nodo(
	nodo: Node3D,
	altura_pies: float = ALTURA_PIES_DEFECTO,
	avance: float = AVANCE_DEFECTO
) -> Dictionary:
	if nodo == null:
		return {}
	var superficie := _superficie_asiento_global(nodo)
	var pos := superficie
	pos += (-nodo.global_transform.basis.z) * avance
	pos.y += altura_pies
	return {
		"posicion": pos,
		"rotacion": nodo.global_rotation,
	}

static func _superficie_asiento_global(nodo: Node3D) -> Vector3:
	var col := _mejor_collision(nodo)
	if col and col.shape:
		var gt := col.global_transform
		var escala := gt.basis.get_scale()
		var arriba_local := Vector3.ZERO
		if col.shape is BoxShape3D:
			arriba_local.y = (col.shape as BoxShape3D).size.y * 0.5 * escala.y
		elif col.shape is CapsuleShape3D:
			var cap := col.shape as CapsuleShape3D
			arriba_local.y = (cap.height * 0.5 + cap.radius) * escala.y
		elif col.shape is CylinderShape3D:
			arriba_local.y = (col.shape as CylinderShape3D).height * 0.5 * escala.y
		elif col.shape is SphereShape3D:
			arriba_local.y = (col.shape as SphereShape3D).radius * escala.y
		return gt * arriba_local
	var centro := nodo.global_position
	if nodo is CollisionShape3D:
		return centro
	for hijo in nodo.get_children():
		if hijo is Node3D:
			var p := _superficie_asiento_global(hijo as Node3D)
			if p != hijo.global_position or hijo.get_child_count() == 0:
				return p
	return centro

static func _mejor_collision(nodo: Node) -> CollisionShape3D:
	var mejor: CollisionShape3D = null
	var mejor_area := 0.0
	var cols: Array[CollisionShape3D] = []
	_recolectar_collisions(nodo, cols)
	for c in cols:
		if c.shape == null:
			continue
		var area := _area_aprox(c.shape)
		if area > mejor_area:
			mejor_area = area
			mejor = c
	return mejor

static func _recolectar_collisions(nodo: Node, out: Array[CollisionShape3D]) -> void:
	if nodo is CollisionShape3D:
		out.append(nodo)
	for hijo in nodo.get_children():
		_recolectar_collisions(hijo, out)

static func _area_aprox(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		var s := (shape as BoxShape3D).size
		return s.x * s.y * s.z
	if shape is CapsuleShape3D:
		var c := shape as CapsuleShape3D
		return c.radius * c.radius * c.height
	return 1.0
