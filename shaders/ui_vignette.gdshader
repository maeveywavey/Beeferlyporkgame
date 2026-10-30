shader_type canvas_item;
// Modal backdrop: the world darkens toward the edges, like a lamp-lit room,
// instead of a flat grey veil.
uniform float strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.82));
	float a = mix(0.28, 0.78, smoothstep(0.18, 0.78, d)) * strength;
	COLOR = vec4(0.045, 0.028, 0.016, a);
}
