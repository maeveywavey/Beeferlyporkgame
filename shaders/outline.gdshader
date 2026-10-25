// Inverted-hull ink outline drawn as a next pass behind the toon material.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.08, 0.06, 0.07, 1.0);
uniform float width = 0.009;
uniform float max_distance = 45.0;

void vertex() {
	// Keep the line roughly constant on screen, fading out far away.
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = -view_pos.z;
	float w = width * clamp(d * 0.12, 0.6, 2.2) * step(d, max_distance);
	// compensate for node scale so imported models with odd units keep a fine line
	float sc = max(length(MODEL_MATRIX[0].xyz), 1e-4);
	VERTEX += normalize(NORMAL) * w / sc;
}

void fragment() {
	ALBEDO = ink.rgb;
}
