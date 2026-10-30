// PS1-style 2D stand-ins for 3D objects: foliage clumps, pines, grass tufts
// and the mountain backdrop are painted images on flat cards. Cards turn to
// face the camera (fully, or only about the vertical axis), are cut out with
// alpha scissor and are lit by a flat tint set per scene.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

uniform sampler2D image : source_color, filter_linear_mipmap;
uniform vec4 light_tint : source_color = vec4(1.0);
// 0 = fixed card, 1 = turn about the vertical axis, 2 = face the camera fully
uniform int billboard = 1;
uniform float cutoff : hint_range(0.0, 1.0) = 0.45;
uniform float saturation : hint_range(0.0, 1.5) = 0.8;
// UV units per metre across and up the card
uniform vec2 uv_per_m = vec2(0.0);

#include "res://shaders/ps1.gdshaderinc"

void vertex() {
	if (billboard == 2) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	} else if (billboard == 1) {
		vec3 to_cam = INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz;
		to_cam.y = 0.0;
		vec3 fwd = normalize(to_cam + vec3(1e-4, 0.0, 0.0));
		vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
		float sx = length(MODEL_MATRIX[0].xyz);
		float sy = length(MODEL_MATRIX[1].xyz);
		mat4 m = mat4(vec4(right * sx, 0.0), vec4(0.0, sy, 0.0, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = VIEW_MATRIX * m;
	}
	PS1_VERTEX(UV)
}

void fragment() {
	vec4 t = ps1_texture2(image, UV, uv_per_m);
	if (t.a < cutoff) {
		discard;
	}
	vec3 c = t.rgb * light_tint.rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(g), c, saturation);
}
