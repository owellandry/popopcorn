@tool
extends Node3D

func _ready():
	var anim = load("res://assets/animations/walk.anim")
	print("tracks: ", anim.get_track_count())
	for i in range(anim.get_track_count()):
		var path = anim.track_get_path(i)
		var type = anim.track_get_type(i)
		var keys = anim.track_get_key_count(i)
		if keys > 1 or i < 3:
			print("track ", i, ": path=", path, " type=", type, " keys=", keys)
			if keys > 0:
				for k in range(min(keys, 2)):
					var val = anim.track_get_key_value(i, k)
					var t = typeof(val)
					if t == TYPE_QUATERNION:
						print("  key", k, " quat: ", val, " euler: ", val.get_euler())
					elif t == TYPE_VECTOR3:
						print("  key", k, " vec3: ", val)
	print("done")
	get_tree().quit()
