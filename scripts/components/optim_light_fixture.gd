@tool
extends Node3D

## Automatically disables expensive shadow-casting lights on decorative fixtures at runtime.
## Keeps them in the editor for preview.

@export var disable_at_runtime: bool = true
@export var force_no_shadows: bool = true
@export var energy_multiplier: float = 0.6

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if not disable_at_runtime:
		return

	for child in get_children():
		if child is OmniLight3D or child is SpotLight3D:
			if force_no_shadows:
				child.shadow_enabled = false
			child.light_energy *= energy_multiplier
			# For very small decorative lights, we can even hide some
			if child.omni_range < 3.0 and child.light_energy < 0.9:
				child.visible = false  # completely remove tiny lights at runtime