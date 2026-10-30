// Double-sided models (thin cloth and armour panels; people, gear, animals, props): plain Lambert light on a painted
// texture, no cel bands, rim light or outlines. Textures go through the PS1
// layer at the shared world texel size (uv_per_m is set from the mesh).
// tex_mix blends two textures (light and dark skin) for any skin tone.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D albedo_tex_b : source_color, filter_linear_mipmap;
uniform float tex_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation : hint_range(0.0, 2.0) = 0.8;
uniform float texture_desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);
// UV units per metre of this surface; 0 = unknown (no texel snapping)
uniform float uv_per_m = 0.0;
// texels per metre relative to the shared PS1 size (characters use 2: half-size pixels)
uniform float texel_mult = 1.0;
// painted grain for untextured, single-colour parts (hats, armour, weapons,
// mounts): wear and shading worked out from the snapped model-space position
uniform float grain = 0.0;
// cut-out textures (leaves, hair cards): alpha below this is discarded
uniform float alpha_cut = 0.0;

varying vec3 obj_pos;

float g_hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float g_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(g_hash(i), g_hash(i + vec3(1, 0, 0)), f.x), mix(g_hash(i + vec3(0, 1, 0)), g_hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(g_hash(i + vec3(0, 0, 1)), g_hash(i + vec3(1, 0, 1)), f.x), mix(g_hash(i + vec3(0, 1, 1)), g_hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

#include "res://shaders/ps1.gdshaderinc"

void vertex() {
	obj_pos = VERTEX;
	PS1_VERTEX(UV)
}

void fragment() {
	vec4 a = ps1_texture(albedo_tex, UV, uv_per_m / texel_mult);
	vec4 b = ps1_texture(albedo_tex_b, UV, uv_per_m / texel_mult);
	vec3 t = mix(a.rgb, b.rgb, tex_mix);
	float tg = dot(t, vec3(0.299, 0.587, 0.114));
	t = mix(t, vec3(tg), texture_desaturate);
	vec3 c = t * tint.rgb;
	if (grain > 0.0) {
		float tm = ps1_texel_m * texel_mult;
		vec3 p = tm > 0.0 ? (floor(obj_pos * tm) + 0.5) / tm : obj_pos;
		float folds = g_noise(p * vec3(6.0, 2.5, 6.0)) * 0.6 + g_noise(p * 14.0) * 0.4;
		float wear = g_noise(p * 3.0 + 17.0);
		c *= mix(1.0, 0.78 + folds * 0.34, grain);
		c = mix(c, c * vec3(0.82, 0.76, 0.68), step(0.7, wear) * 0.5 * grain);
		c *= mix(1.0, 0.9 + g_hash(floor(p * max(tm, 8.0))) * 0.2, grain);
	}
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(grey), c, saturation);
	EMISSION = emission_color.rgb * emission_strength;
	ALPHA = alpha_cut > 0.0 ? mix(a.a, b.a, tex_mix) : 1.0;
	ALPHA_SCISSOR_THRESHOLD = max(alpha_cut, 0.001);
}
