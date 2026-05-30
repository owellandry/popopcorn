shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// Normal local hacia el lado TRANSPARENTE (desde aquí se ve el otro espacio).
uniform vec3 lado_transparente = vec3(0.0, 0.0, 1.0);

uniform vec4 color_transparente : source_color = vec4(0.75, 0.88, 0.95, 0.12);
uniform vec4 color_opaco : source_color = vec4(0.08, 0.09, 0.11, 1.0);
uniform float rugosidad_transparente : hint_range(0.0, 1.0) = 0.03;
uniform float rugosidad_opaco : hint_range(0.0, 1.0) = 0.98;
uniform float metalico_transparente : hint_range(0.0, 1.0) = 0.4;
uniform float especular_transparente : hint_range(0.0, 1.0) = 0.92;
uniform float umbral_lado : hint_range(-0.3, 0.3) = 0.0;
uniform float suavizado_lado : hint_range(0.0, 0.25) = 0.04;

void fragment() {
	vec3 lado_world = normalize((MODEL_NORMAL_MATRIX * lado_transparente));
	vec3 hacia_camara = normalize(CAMERA_POSITION_WORLD - NODE_POSITION_WORLD);
	float lado = dot(hacia_camara, lado_world);
	float ver_a_traves = smoothstep(
		umbral_lado - suavizado_lado,
		umbral_lado + suavizado_lado,
		lado
	);

	if (ver_a_traves > 0.5) {
		ALBEDO = color_transparente.rgb;
		ALPHA = color_transparente.a;
		ROUGHNESS = rugosidad_transparente;
		METALLIC = metalico_transparente;
		SPECULAR = especular_transparente;
	} else {
		ALBEDO = color_opaco.rgb;
		ALPHA = 1.0;
		ROUGHNESS = rugosidad_opaco;
		METALLIC = 0.0;
		SPECULAR = 0.1;
	}
}
