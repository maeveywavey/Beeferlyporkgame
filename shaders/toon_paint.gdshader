// Cel shader for architecture and set dressing, aiming for the look of the
// series' painted backgrounds: vertex colours as flat paint, a low-frequency
// "brush" variation in world space so large surfaces never read as CG-flat,
// two-tone lighting with cool shadows, and a soft painted rim.
shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 shadow_tint : source_color = vec4(0.6, 0.6, 0.85, 1.0);
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.1;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.05;
uniform float brush_strength : hint_range(0.0, 0.5) = 0.09;
uniform float brush_scale = 0.35;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.12;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0;

varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = COLOR.rgb * tint.rgb;
	// two octaves of soft value noise, stretched horizontally like brush strokes
	vec3 p = world_pos * brush_scale * vec3(0.6, 1.4, 0.6);
	float n = noise(p) * 0.65 + noise(p * 3.1) * 0.35;
	c *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	ALBEDO = c;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = c * rim * rim_strength + c * emission_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndl) * ATTENUATION;
	vec3 shade = mix(shadow_tint.rgb * 0.58, vec3(1.0), lit);
	DIFFUSE_LIGHT += ALBEDO * shade * LIGHT_COLOR / PI;
}
