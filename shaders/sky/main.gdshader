shader_type sky;

group_uniforms Sky;
uniform vec4 sky_day : source_color = vec4(0.0,0.3,0.7,1.0);
uniform vec4 horizon_day : source_color = vec4(0.75,0.85,0.85,1.0);
uniform vec4 horizon_sunset : source_color = vec4(0.9,0.4,0.1,1.0);
uniform vec4 sky_sunset : source_color = vec4(0.15, 0.2, 0.4, 1.0);
uniform vec4 horizon_night : source_color = vec4(0.01, 0.01, 0.02, 1.0);
uniform vec4 sky_night : source_color = vec4(0.005, 0.005, 0.01, 1.0);
uniform float day_night_mix : hint_range(-1.0, 1.0, 0.1) = 0.8;
uniform bool use_directional_light = true;
uniform float horizon_exponent = 2.0;
uniform float sunset_amount_exponent = 0.7;
uniform float night_amount_exponent = 4.0;

group_uniforms Clouds;
uniform sampler2D cloud_tex_01 : hint_default_black, filter_linear, repeat_enable;
uniform sampler2D cloud_tex_02 : hint_default_black, filter_linear, repeat_enable;
uniform vec4 cloud_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec2 cloud_tiling = vec2(1.0);
uniform vec2 wind_speed = vec2(0.02); // Viento súper lento y realista
uniform float cloud_density : hint_range(0.0, 5.0, 0.1) = 0.7;
uniform float cloud_depth = 2.0;
uniform float cloud_shape_exponent = 2.0;
uniform float cloud_occlude_exponent = 1.0;

group_uniforms Sun;
uniform float sun_scale = 0.05;
uniform float sun_strength = 15.0;
uniform vec4 sun_color : source_color = vec4(1.0,0.9,0.0,1.0);

// Funciones para generar nubes suaves (Value Noise)
float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f); // Interpolación suave (smoothstep)
    
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion para nubes más realistas y esponjosas
float fbm(vec2 st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotar para reducir artefactos en forma de cuadrícula
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 4; ++i) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float plane_intersection(vec3 origin, vec3 normal, vec3 ray_start, vec3 ray_dir) {
	return dot(origin - ray_start, normal) / dot(ray_dir, normal);
}

float get_cloud_height(sampler2D tex, vec2 uv) {
	float height;
	
	// Si hay textura válida la usa, si no, usa nuestro generador de nubes suaves
	vec4 tex_val = texture(tex, uv);
	if (tex_val.r > 0.01 || tex_val.g > 0.01 || tex_val.b > 0.01) {
		height = tex_val.r;
	} else {
		// Nubes procedurales SUAVES en vez de píxeles/cubos
		height = fbm(uv * 3.0);
	}
	
	height = clamp((height - (1.0 - cloud_density)) / (cloud_density), 0.0, 1.0);
	return pow(height, cloud_shape_exponent);
}

void sky() {
	float t = plane_intersection(vec3(0.0, 1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0), EYEDIR);
	
	// day_night_mix lo controla ciclo_dia_noche.gd (LIGHT0 solo dibuja el disco solar)
	float blend = day_night_mix;

	vec3 sky = vec3(0.0);
	vec3 horizon_color = vec3(0.0);
	vec3 sky_color = vec3(0.0);

	float cloud_value = 0.0;
	if(t >= 0.0){
		vec3 wind = vec3(wind_speed.x, 0.0, wind_speed.y) * TIME * 0.1;
		vec3 tiling = vec3(cloud_tiling.x, 1.0, cloud_tiling.y) * 0.2;
		vec3 cloud_pos1 = EYEDIR * t * tiling + wind;
		vec3 cloud_pos2 = EYEDIR * t * tiling + (wind*0.5);

		float height1 = get_cloud_height(cloud_tex_01, cloud_pos1.xz);
		float height2 = get_cloud_height(cloud_tex_02, cloud_pos2.xz);
		cloud_pos1 += EYEDIR * height1 * cloud_depth * 0.1;
		cloud_pos2 += EYEDIR * height2 * cloud_depth * 0.1;
		height1 = get_cloud_height(cloud_tex_01,cloud_pos1.xz);
		height2 = get_cloud_height(cloud_tex_02,cloud_pos2.xz);
		cloud_value = min(height1, height1 * height2);

		cloud_value *= smoothstep(0.0, 0.2, EYEDIR.y);
	}

	float sun_distance = clamp(1.0 - distance(EYEDIR, LIGHT0_DIRECTION) - pow(cloud_value,cloud_occlude_exponent),0.0,1.0);
	float sun_disc = clamp(smoothstep(1.0 - sun_scale, 1.0, sun_distance), 0.0, 1.0);
	float sun_glow = clamp(0.0, 1.0, (pow(sun_distance, 4.0)*0.07));
	vec3 sun = mix(vec3(0.0), sun_color.rgb * sun_strength, max(sun_disc, sun_glow));

	horizon_color = mix(horizon_sunset, horizon_day, clamp(blend,0.0,1.0)).rgb;
	horizon_color = mix(horizon_night.rgb, horizon_color, pow(clamp(1.0+blend,0.0,1.0), 4.0)).rgb;

	// Colores del cielo simplificados, CERO estrellas
	sky_color = mix(sky_sunset, sky_day, clamp(blend,0.0,1.0)).rgb;
	sky_color = mix(sky_night.rgb, sky_color, clamp(pow(1.0+blend, 4.0),0.0,1.0)).rgb;

	sky = mix(sky_color, horizon_color, pow(1.0 - abs(EYEDIR.y), horizon_exponent));
	sky = mix(sky, cloud_color.rgb * 1.0, pow(cloud_value, 0.8));

	sky = mix(sky, mix(sky_color * 0.5, horizon_color, EYEDIR.y + 1.0).rgb, clamp(pow(1.0 - EYEDIR.y, 2.0), 0.0, 1.0));
	if(use_directional_light) {
		sky += sun * clamp(pow(EYEDIR.y + 1.0, 16.0),0.0,1.0);
	}

	COLOR = sky;
}
