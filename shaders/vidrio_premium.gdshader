shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

// === Lado EXTERIOR (cara frontal) — vidrio transparente claro ===
uniform vec4 color_frente : source_color = vec4(0.75, 0.88, 0.95, 0.12);
uniform float rugosidad_frente : hint_range(0.0, 1.0) = 0.04;
uniform float metalico_frente : hint_range(0.0, 1.0) = 0.15;
uniform float especular_frente : hint_range(0.0, 1.0) = 0.95;

// === Lado INTERIOR (cara trasera) — vidrio esmerilado / borroso ===
uniform vec4 color_esmeril : source_color = vec4(0.88, 0.92, 0.95, 0.78);
uniform float rugosidad_esmeril : hint_range(0.0, 1.0) = 0.92;
uniform float metalico_esmeril : hint_range(0.0, 1.0) = 0.0;
uniform float especular_esmeril : hint_range(0.0, 1.0) = 0.2;
uniform float escala_ruido : hint_range(0.5, 20.0) = 8.0;
uniform float intensidad_ruido : hint_range(0.0, 0.5) = 0.08;

// Función de ruido simple para simular textura esmerilada
float rand2(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise_esmeril(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f); // smoothstep
	float a = rand2(i);
	float b = rand2(i + vec2(1.0, 0.0));
	float c = rand2(i + vec2(0.0, 1.0));
	float d = rand2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	if (FRONT_FACING) {
		// Cara exterior: vidrio transparente, ligeramente azulado
		ALBEDO = color_frente.rgb;
		ALPHA = color_frente.a;
		ROUGHNESS = rugosidad_frente;
		METALLIC = metalico_frente;
		SPECULAR = especular_frente;
	} else {
		// Cara interior: vidrio esmerilado con patrón de ruido
		vec2 uv_ruido = UV * escala_ruido;
		float n = noise_esmeril(uv_ruido);
		
		// Variación sutil de albedo con el ruido (simula el efecto arenado)
		vec3 albedo_esmeril = color_esmeril.rgb + vec3(n * intensidad_ruido);
		
		ALBEDO = albedo_esmeril;
		ALPHA = color_esmeril.a;
		ROUGHNESS = rugosidad_esmeril - n * 0.05;
		METALLIC = metalico_esmeril;
		SPECULAR = especular_esmeril;
	}
}
