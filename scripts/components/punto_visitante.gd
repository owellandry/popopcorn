extends Marker3D
class_name PuntoVisitante

enum Tipo {
	SPAWN_EXTERIOR,
	SALIDA_EXTERIOR,
	PUERTA_ENTRADA,
	FILA,
	BANCA,
	BANO,
	PASILLO_SALAS,
	CONCESION,
	ZONA_COLADO,
	ZONA_PAREJA,
	MESA,
	SALIDA_IZQUIERDA,
}

@export var tipo: Tipo = Tipo.SPAWN_EXTERIOR

func _ready() -> void:
	add_to_group("punto_visitante")