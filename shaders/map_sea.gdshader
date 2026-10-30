// The world map's sea, in the same three styles as map_terrain.gdshader:
// depth from the baked heights, shore bands from the coast distance.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform sampler2D info_lin : filter_linear, repeat_disable;
uniform int style = 0;
uniform vec2 grid = vec2(801.0, 601.0);
uniform float step_m = 2.0;
uniform vec2 map_size = vec2(1600.0, 1200.0);
uniform float daylight = 1.0;

varying vec3 wpos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float line_px(float v, float px) {
	float w = max(fwidth(v), 1e-4) * px;
	return 1.0 - smoothstep(0.0, w, abs(v));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = wpos.xz;
	vec2 uv = (xz / step_m + 0.5) / grid;
	bool inside = all(greaterThanEqual(xz, vec2(0.0))) && all(lessThanEqual(xz, map_size));
	float depth = inside ? clamp(-texture(height_tex, uv).r, 0.0, 7.0) : 7.0;
	float coast = inside ? (texture(info_lin, uv).g * 255.0 - 128.0) / 4.0 : -40.0;
	float off = -coast;   // distance out to sea
	if (coast > 0.6) {
		discard;
	}
	vec3 c;
	if (style == 0) {
		vec3 shallow = vec3(0.32, 0.52, 0.58);
		vec3 deep = vec3(0.1, 0.2, 0.32);
		c = mix(shallow, deep, smoothstep(0.5, 6.5, depth));
		c *= 0.94 + 0.08 * vnoise(xz * 0.05 + TIME * 0.02);
		// pale surf just off the beach
		c = mix(c, vec3(0.75, 0.8, 0.78), (1.0 - smoothstep(0.0, 2.2, off)) * 0.5);
		float g = dot(c, vec3(0.3, 0.59, 0.11));
		c = mix(vec3(g), c, 0.85);
	} else if (style == 1) {
		vec3 sea = vec3(0.66, 0.72, 0.7) * (0.94 + 0.08 * vnoise(xz * 0.03));
		vec3 ink = vec3(0.28, 0.2, 0.13);
		c = mix(sea, sea * vec3(0.86, 0.9, 0.95), smoothstep(1.0, 6.0, depth));
		// ripple lines following the shore, fading out to sea
		float sp = max(3.0, fwidth(off) * 5.0);
		float rip = (fract(off / sp + 0.5) - 0.5) * sp;
		float band = line_px(rip, 1.1) * (1.0 - smoothstep(sp * 0.8, sp * 4.5, off));
		c = mix(c, ink, band * 0.55);
		// sparse wave marks in open water
		vec2 cell = floor(xz / 26.0);
		vec2 lp = xz - (cell + 0.5) * 26.0;
		float wave = step(0.7, hash(cell)) * (1.0 - smoothstep(0.15, 0.45, abs(lp.y - sin(lp.x * 0.5) * 0.9))) * step(abs(lp.x), 6.0);
		c = mix(c, ink, wave * 0.5 * smoothstep(14.0, 24.0, off));
	} else {
		vec3 paper = vec3(0.9, 0.9, 0.86);
		c = mix(paper * vec3(0.9, 0.94, 0.97), paper * vec3(0.78, 0.84, 0.88), smoothstep(0.5, 6.5, depth));
		// a few long brushed swell lines
		float swell = abs(fract((xz.y + sin(xz.x * 0.02) * 12.0) / 34.0) - 0.5);
		float mark = (1.0 - smoothstep(0.0, 0.02, swell)) * step(0.55, vnoise(xz * vec2(0.01, 0.05)));
		c = mix(c, vec3(0.35, 0.4, 0.45), mark * 0.35 * smoothstep(6.0, 14.0, off));
		// a wash of grey hugging the coast
		c = mix(c, vec3(0.55, 0.6, 0.64), (1.0 - smoothstep(0.0, 6.0, off)) * 0.35);
	}
	c *= mix(0.45, 1.0, daylight);
	ALBEDO = c;
}
