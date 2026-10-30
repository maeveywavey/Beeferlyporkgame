// Vertex-painted architecture and set dressing: Lambert light, with grain
// variation in world space at the shared PS1 texel size.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float brush_strength : hint_range(0.0, 0.5) = 0.09;
uniform float brush_scale = 0.35;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0;

varying vec3 world_pos;

#include "res://shaders/ps1.gdshaderinc"

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
	PS1_VERTEX(UV)
}

void fragment() {
	vec3 c = COLOR.rgb * tint.rgb;
	// grain variation in world space, snapped to the shared texel size so walls
	// and roofs are as pixelated as everything else
	vec3 wp = ps1_snap_m3(world_pos);
	vec3 p = wp * brush_scale * vec3(0.6, 1.4, 0.6);
	float n = noise(p) * 0.65 + noise(p * 3.1) * 0.35;
	c *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	c *= 0.92 + hash(floor(wp * 8.0)) * 0.16;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(g), c, 0.8);
	EMISSION = c * emission_strength;
}
