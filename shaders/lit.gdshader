// Realistic, desaturated surfaces for ground, cliffs, boulders and bark:
// Lambert light, a detail texture (by UV, or projected from the world for
// ground and rock), a large-scale variation texture so no surface tiles
// visibly, and the PS1 layer (shaders/ps1.gdshaderinc).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D macro_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation : hint_range(0.0, 1.5) = 0.75;
// 0 = use UV; 1 = project from world XZ (ground); 2 = project from the side (cliffs)
uniform int proj_mode = 0;
uniform float detail_scale = 0.25;
uniform float macro_scale = 0.015;
uniform float macro_strength : hint_range(0.0, 1.0) = 0.35;
uniform bool use_vertex_color = true;

#include "res://shaders/ps1.gdshaderinc"

varying vec3 world_pos;
varying vec3 world_normal;
varying vec2 tex_uv;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tex_uv = UV;
	if (proj_mode == 1) {
		tex_uv = world_pos.xz * detail_scale;
	} else if (proj_mode == 2) {
		// pick the side plane the face looks along, for cliff walls
		vec3 n = abs(world_normal);
		tex_uv = (n.x > n.z ? world_pos.zy : world_pos.xy) * detail_scale;
		if (n.y > 0.75) {
			tex_uv = world_pos.xz * detail_scale;
		}
	}
	PS1_VERTEX(tex_uv)
}

void fragment() {
	vec3 c = ps1_texture(detail_tex, tex_uv).rgb;
	vec3 m = texture(macro_tex, world_pos.xz * macro_scale).rgb;
	c *= mix(vec3(1.0), m * 2.0, macro_strength);
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	c *= tint.rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(g), c, saturation);
}
