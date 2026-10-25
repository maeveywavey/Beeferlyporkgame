// Cel shader in the style of the original animated series: two flat tones,
// cool-tinted shadows, a painted rim light and optional texture blending
// (used to mix light and dark skin textures for any skin tone).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D albedo_tex_b : source_color, filter_linear_mipmap;
uniform float tex_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 shadow_tint : source_color = vec4(0.62, 0.6, 0.82, 1.0);
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.12;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.04;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.22;
uniform float saturation : hint_range(0.0, 2.0) = 1.12;
uniform float texture_desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	vec4 b = texture(albedo_tex_b, UV);
	vec3 t = mix(a.rgb, b.rgb, tex_mix);
	float tg = dot(t, vec3(0.299, 0.587, 0.114));
	t = mix(t, vec3(tg), texture_desaturate);
	vec3 c = t * tint.rgb;
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(grey), c, saturation);
	ALBEDO = c;
	EMISSION = emission_color.rgb * emission_strength;
	// Painted rim light
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += c * rim * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndl) * ATTENUATION;
	vec3 shade = mix(shadow_tint.rgb * 0.55, vec3(1.0), lit);
	DIFFUSE_LIGHT += ALBEDO * shade * LIGHT_COLOR / PI * 1.0;
}
