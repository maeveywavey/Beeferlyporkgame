shader_type canvas_item;
// Title screen: an ink-wash landscape on paper. Four ridges of mountains,
// darker as they come forward, mist pooling in the valleys, a cinnabar sun,
// and slow cloud bands. Everything is generated; nothing is an image.

uniform float drift = 0.012;
uniform vec3 paper = vec3(0.93, 0.885, 0.79);
uniform vec3 sun_col = vec3(0.76, 0.2, 0.11);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * drift;
	vec3 col = paper * (0.93 + 0.07 * fbm(uv * vec2(9.0, 7.0)));
	// sun
	float sd = length((uv - vec2(0.72, 0.24)) * vec2(1.78, 1.0));
	col = mix(col, sun_col, smoothstep(0.062, 0.058, sd) * 0.9);
	// mountain ridges, back to front
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float base = 0.5 + fi * 0.11;
		float ridge = base - 0.22 * fbm(vec2(uv.x * (1.3 + fi * 0.6) + fi * 7.3 + t * (0.3 + fi * 0.2), fi * 1.7)) - 0.04 * sin(uv.x * (3.0 + fi) + fi);
		float mask = smoothstep(ridge - 0.002, ridge + 0.002, uv.y);
		vec3 ink = mix(vec3(0.6, 0.56, 0.5), vec3(0.11, 0.085, 0.07), fi / 3.0);
		// dry-brush texture inside the ink
		ink *= 0.9 + 0.2 * fbm(uv * vec2(16.0, 34.0) + vec2(fi * 3.0, 0.0));
		float mist = smoothstep(ridge + 0.02, ridge + 0.26, uv.y) * (1.0 - fi * 0.22);
		vec3 layer = mix(ink, paper, mist * 0.75);
		col = mix(col, layer, mask);
	}
	// cloud bands drifting across the upper sky
	float cl = fbm(vec2(uv.x * 2.5 - t * 3.0, uv.y * 9.0 + 3.0));
	col = mix(col, paper * 1.02, smoothstep(0.58, 0.78, cl) * 0.45 * smoothstep(0.75, 0.15, uv.y));
	// vignette like the edge of a scroll
	vec2 c = uv - 0.5;
	col *= 1.0 - dot(c, c) * 0.7;
	COLOR = vec4(col, 1.0);
}
