// A hand-inked flipbook sprite: flat colour, hard edges, frames that step
// (never blend) at a fixed rate. Faces the camera:
//   billboard 1 = turns about the vertical axis (ground fire, burning people)
//   billboard 2 = fully faces the camera
//   billboard 3 = faces the camera and turns so the sprite's +X leads along the
//                 node's +Z (fireballs: the head leads, the tail trails)
// Shrinks away as the camera comes within a couple of metres.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform int frames = 8;
uniform float fps = 12.0;
uniform float phase = 0.0;
uniform int billboard = 1;
uniform vec4 tint : source_color = vec4(1.0);
uniform float near_fade = 1.2;

void vertex() {
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	float k = clamp((length(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz) - near_fade) / 1.8, 0.0, 1.0);
	sx *= k;
	sy *= k;
	vec3 right;
	vec3 up;
	vec3 fwd;
	if (billboard == 1) {
		vec3 to_cam = INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz;
		to_cam.y = 0.0;
		fwd = normalize(to_cam + vec3(1e-4, 0.0, 0.0));
		right = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
		up = vec3(0.0, 1.0, 0.0);
	} else {
		right = INV_VIEW_MATRIX[0].xyz;
		up = INV_VIEW_MATRIX[1].xyz;
		fwd = INV_VIEW_MATRIX[2].xyz;
		if (billboard == 3) {
			vec2 v = (VIEW_MATRIX * vec4(normalize(MODEL_MATRIX[2].xyz), 0.0)).xy;
			float a = atan(v.y, v.x);
			vec3 r0 = right;
			vec3 u0 = up;
			right = r0 * cos(a) + u0 * sin(a);
			up = -r0 * sin(a) + u0 * cos(a);
		}
	}
	mat4 m = mat4(vec4(right * sx, 0.0), vec4(up * sy, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
}

void fragment() {
	float f = mod(floor(TIME * fps + phase), float(frames));
	float u = (clamp(UV.x, 0.002, 0.998) + f) / float(frames);
	vec4 t = texture(sheet, vec2(u, UV.y));
	if (t.a < 0.5) {
		discard;
	}
	ALBEDO = t.rgb * tint.rgb;
}
