shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(1.0, 20.0) = 8.0;
uniform vec4 color_popcorn : source_color = vec4(1.0, 0.92, 0.6, 1.0);
uniform bool reverse = false;

// Simple hash noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float n = noise(UV * noise_scale) * 0.15;
	float threshold;
	// Expandir progress al rango 0-1.15 para compensar noise
	float p = progress * 1.2;
	if (reverse) {
		// Reveal: popcorn falls away downward (clear from top to bottom)
		threshold = UV.y + n;
		float alpha = 1.0 - step(threshold, p);
		COLOR = vec4(color_popcorn.rgb, alpha);
	} else {
		threshold = UV.y + n;
		float alpha = step(threshold, p);
		COLOR = vec4(color_popcorn.rgb, alpha);
	}
}
