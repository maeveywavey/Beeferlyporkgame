// The world map's land, in one of three styles, drawn from the baked world
// grids (tools/make_world.py): heights, biome, coast distance, forest, rivers.
//   0  Painted atlas: shaded relief in muted natural colours, forests as
//      canopy, rivers in blue
//   1  Old chart: parchment, ink coastline, hachured mountains, tree marks
//   2  Ink wash: rice paper, mountains in graded ink, mist at their feet,
//      forests as soft blots
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform sampler2D info_near : filter_nearest, repeat_disable;
uniform sampler2D info_lin : filter_linear, repeat_disable;
uniform int style = 0;
uniform vec2 grid = vec2(801.0, 601.0);
uniform float step_m = 2.0;
uniform vec3 light_dir = vec3(-0.6, 0.75, -0.35);
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

float fbm(vec2 p) {
	return vnoise(p) * 0.5 + vnoise(p * 2.1) * 0.3 + vnoise(p * 4.3) * 0.2;
}

vec2 uv_of(vec2 xz) {
	return (xz / step_m + 0.5) / grid;
}

float height_at(vec2 xz) {
	return texture(height_tex, uv_of(xz)).r;
}

// 1 at the line (where v == 0), fading over about `px` screen pixels
float line_px(float v, float px) {
	float w = max(fwidth(v), 1e-4) * px;
	return 1.0 - smoothstep(0.0, w, abs(v));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = wpos.xz;
	vec2 uv = uv_of(xz);
	float h = texture(height_tex, uv).r;
	vec4 inf = texture(info_lin, uv);
	int biome = int(texture(info_near, uv).r * 255.0 + 0.5);
	float coast = (inf.g * 255.0 - 128.0) / 4.0;
	float forest = inf.b;
	float river = inf.a;
	// relief
	float e = step_m;
	float hx = height_at(xz + vec2(e, 0.0)) - height_at(xz - vec2(e, 0.0));
	float hz = height_at(xz + vec2(0.0, e)) - height_at(xz - vec2(0.0, e));
	vec3 n = normalize(vec3(-hx, 2.0 * e * 0.55, -hz));
	float shade = clamp(dot(n, normalize(light_dir)), 0.0, 1.0);
	float slope = 1.0 - n.y;
	bool snow = biome == 4;
	bool desert = biome == 5;
	bool swamp = biome == 6;
	bool volcanic = biome == 7;
	bool beach = biome == 9;
	vec3 c;
	if (style == 0) {
		// --- painted atlas ---
		vec3 low = vec3(0.45, 0.55, 0.32);
		vec3 up = vec3(0.6, 0.6, 0.42);
		vec3 rock = vec3(0.52, 0.48, 0.43);
		c = mix(low, up, smoothstep(2.0, 7.0, h));
		c = mix(c, rock, smoothstep(7.0, 12.0, h));
		c = mix(c, vec3(0.93, 0.94, 0.96), smoothstep(15.0, 19.0, h) * 0.85);
		if (desert) c = mix(vec3(0.82, 0.72, 0.5), rock, smoothstep(8.0, 14.0, h) * 0.5);
		if (volcanic) c = mix(vec3(0.36, 0.3, 0.27), vec3(0.5, 0.45, 0.4), smoothstep(4.0, 12.0, h));
		if (swamp) c = mix(vec3(0.3, 0.36, 0.26), vec3(0.24, 0.34, 0.36), step(0.55, fbm(xz * 0.25)));
		if (snow) c = mix(vec3(0.9, 0.93, 0.97), vec3(0.78, 0.84, 0.92), fbm(xz * 0.05) * 0.6);
		if (beach) c = vec3(0.8, 0.75, 0.58);
		// forest canopy: dark clumps with crowns
		float canopy = smoothstep(0.3, 0.6, forest) * (0.7 + 0.3 * step(0.45, vnoise(xz * 0.9)));
		c = mix(c, vec3(0.2, 0.32, 0.18) * (0.85 + 0.3 * vnoise(xz * 1.7)), canopy * (snow ? 0.5 : 0.85));
		c *= 0.9 + fbm(xz * 0.08) * 0.2;
		c *= mix(0.55, 1.2, shade);
		c = mix(c, vec3(0.25, 0.45, 0.62), smoothstep(0.35, 0.7, river));
		float g = dot(c, vec3(0.3, 0.59, 0.11));
		c = mix(vec3(g), c, 0.82);
		// a thin dark line at the shore
		c = mix(c, vec3(0.18, 0.2, 0.18), line_px(coast, 1.6) * 0.7);
	} else if (style == 1) {
		// --- old chart ---
		vec3 paper = vec3(0.88, 0.8, 0.62) * (0.92 + 0.12 * fbm(xz * 0.03)) * (0.97 + 0.05 * vnoise(xz * 2.5));
		vec3 ink = vec3(0.28, 0.2, 0.13);
		c = paper;
		if (desert) c *= vec3(1.03, 0.97, 0.84);
		if (swamp) c *= vec3(0.86, 0.92, 0.8);
		if (volcanic) c *= vec3(0.86, 0.8, 0.74);
		if (snow) c = mix(c, vec3(0.93, 0.92, 0.88), 0.6);
		// hachures: short strokes down the slope, denser where steeper and in shade
		vec2 grad = normalize(vec2(hx, hz) + 1e-4);
		vec2 across = vec2(-grad.y, grad.x);
		// spacing grows with distance so the strokes stay a few pixels apart
		float spacing = max(2.5, fwidth(xz.x) * 5.0);
		float along = dot(xz, across) / spacing;
		float lines = abs(fract(along) - 0.5) * spacing;
		float strength = smoothstep(0.015, 0.12, slope) * (1.25 - shade * 0.6);
		float hatch = line_px(lines, 1.3) * step(0.1, strength);
		// strokes are broken into short dashes down the slope
		hatch *= step(0.35, fract(dot(xz, grad) / (spacing * 2.2)));
		c = mix(c, ink, hatch * clamp(strength, 0.0, 0.85));
		// a green wash along the coasts, as on hand-coloured charts
		c = mix(c, vec3(0.7, 0.75, 0.55), (1.0 - smoothstep(0.0, 9.0, coast)) * 0.35);
		// tree marks: little round crowns on stems where the forest is thick
		vec2 cell = floor(xz / 7.0);
		vec2 ctr = (cell + 0.5 + (vec2(hash(cell), hash(cell + 7.1)) - 0.5) * 0.5) * 7.0;
		float d = length(xz - ctr - vec2(0.0, -0.8));
		float stem = step(abs(xz.x - ctr.x), 0.25) * step(0.0, xz.y - ctr.y) * step(xz.y - ctr.y, 1.6);
		float crown = 1.0 - smoothstep(1.35, 1.6, d);
		float ring = crown * smoothstep(0.85, 1.15, d);
		float has_tree = step(0.45, forest) * step(hash(cell + 3.3), forest);
		c = mix(c, ink, has_tree * max(ring, stem) * 0.85);
		if (swamp) c = mix(c, ink * 1.2, step(0.92, fract(xz.y * 0.5 + vnoise(xz * 0.3))) * 0.35);
		if (desert) c = mix(c, ink, step(0.985, hash(floor(xz * 1.5))) * 0.5);
		c = mix(c, vec3(0.32, 0.38, 0.45), smoothstep(0.3, 0.6, river));
		// the coastline, inked, with a darker band just inside
		c = mix(c, ink, max(line_px(coast, 1.8), 1.0 - smoothstep(0.0, 0.6, coast)));
		c *= mix(0.92, 1.03, shade);
	} else {
		// --- ink wash ---
		vec3 paper = vec3(0.92, 0.9, 0.84) * (0.95 + 0.07 * fbm(xz * 0.04));
		vec3 ink = vec3(0.12, 0.13, 0.14);
		// a pale warm wash over all land, darker inland, so land reads against the sea
		c = paper * mix(vec3(0.95, 0.92, 0.86), vec3(0.86, 0.84, 0.78), smoothstep(0.0, 40.0, coast));
		// mountains: ink graded from the peaks, broken by brush texture
		float relief = smoothstep(2.0, 13.0, h);
		float brush = fbm(vec2(xz.x * 0.12, xz.y * 0.5));
		float wash = relief * (0.55 + 0.45 * (1.0 - shade)) * (0.75 + 0.5 * brush);
		c = mix(c, ink, clamp(wash, 0.0, 0.85));
		// mist at the mountains' feet
		float mist = smoothstep(1.5, 4.0, h) * (1.0 - smoothstep(4.0, 8.0, h)) * fbm(xz * 0.05 + 3.0);
		c = mix(c, paper * 1.03, mist * 0.5);
		// soft green-grey blots for forests, ochre for desert, warm for volcanic land
		float blot = smoothstep(0.35, 0.7, forest) * smoothstep(0.35, 0.65, fbm(xz * 0.18));
		c = mix(c, vec3(0.42, 0.48, 0.42), blot * 0.55);
		if (desert) c = mix(c, vec3(0.85, 0.72, 0.5), 0.35);
		if (volcanic) c = mix(c, vec3(0.62, 0.42, 0.36), 0.25);
		if (swamp) c = mix(c, vec3(0.5, 0.56, 0.5), 0.35 * fbm(xz * 0.3));
		if (snow) c = mix(c, vec3(0.97, 0.97, 0.98), 0.5 * (1.0 - relief));
		c = mix(c, vec3(0.45, 0.52, 0.58), smoothstep(0.35, 0.7, river) * 0.8);
		// a brush stroke along the coast, thick and thin
		float thick = 1.2 + 2.2 * vnoise(xz * 0.03);
		c = mix(c, ink, max(line_px(coast, thick), 1.0 - smoothstep(0.0, 0.5, coast)) * 0.88);
	}
	c *= mix(0.45, 1.0, daylight);
	ALBEDO = c;
}
