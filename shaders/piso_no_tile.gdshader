shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(0.5, 0.48, 0.45, 1.0);
uniform float uv_scale : hint_range(0.1, 10.0) = 0.5;
uniform float blend_sharpness : hint_range(0.1, 10.0) = 3.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

// Rompe repetición mezclando la textura en 2 escalas con offset
vec4 textureNoTile(sampler2D tex, vec2 uv) {
	vec2 uv1 = uv;
	vec2 uv2 = uv * 0.37 + vec2(0.53, 0.71); // segunda capa con offset y escala diferente

	vec4 col1 = texture(tex, uv1);
	vec4 col2 = texture(tex, uv2);

	// Mezcla basada en un patrón de ruido simple desde las coordenadas
	float noise = fract(sin(dot(floor(uv * 2.0), vec2(12.9898, 78.233))) * 43758.5453);
	float blend = smoothstep(0.35, 0.65, noise);

	return mix(col1, col2, blend * 0.4);
}

void fragment() {
	vec2 uv = UV * uv_scale;

	// Triplanar simple usando world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 tri_uv = world_pos.xz * uv_scale;

	vec4 col = textureNoTile(albedo_tex, tri_uv);
	ALBEDO = col.rgb * albedo_color.rgb;

	vec4 norm = textureNoTile(normal_tex, tri_uv);
	NORMAL_MAP = norm.rgb;
	NORMAL_MAP_DEPTH = normal_strength;

	vec4 rough = textureNoTile(roughness_tex, tri_uv);
	ROUGHNESS = rough.r;
}
