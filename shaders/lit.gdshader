// Ground, rock and bark, lit plainly (Lambert).
//
// Ground and rock are computed from the world position rather than read from a
// tiling texture, after snapping that position to the shared PS1 texel grid
// (ps1_texel_m). Every face of every rock and every metre of ground therefore
// has texels of the same size, nothing repeats, and no face stretches.
//
// Ground: patches of lush, dark, dry and bare ground with hard edges, in sizes
// from one to four times the base patch size; brown leaf litter under trees
// (amount in vertex alpha) breaks up in irregular, hard-edged clumps.
// Rock (after how real outcrops look): zones of different stone; bedding bands
// only in some zones, of varying thickness and colour, dipping slightly;
// joints with blocks of differing tint in massive zones; iron-oxide staining
// near joints; dark varnish streaks running down faces; lichen on upward faces.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

// 0 = UV-mapped texture (bark), 1 = ground, 2 = rock, 3 = textured ground
// (CC0 tiling textures blended by noise masks), 4 = textured rock
uniform int proj_mode = 0;
uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float uv_per_m = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation : hint_range(0.0, 1.5) = 0.8;
uniform bool use_vertex_color = true;
// ground
uniform vec4 g_lush : source_color = vec4(0.38, 0.47, 0.24, 1.0);
uniform vec4 g_dark : source_color = vec4(0.27, 0.36, 0.18, 1.0);
uniform vec4 g_dry : source_color = vec4(0.55, 0.52, 0.32, 1.0);
uniform vec4 g_bare : source_color = vec4(0.45, 0.39, 0.28, 1.0);
uniform vec4 g_litter : source_color = vec4(0.36, 0.27, 0.17, 1.0);
uniform float patch_m = 16.0;
// rock
uniform vec4 r_a : source_color = vec4(0.5, 0.48, 0.44, 1.0);
uniform vec4 r_b : source_color = vec4(0.6, 0.5, 0.38, 1.0);
uniform vec4 r_c : source_color = vec4(0.42, 0.43, 0.45, 1.0);
uniform vec4 r_stain : source_color = vec4(0.58, 0.34, 0.18, 1.0);
uniform vec4 r_varnish : source_color = vec4(0.18, 0.15, 0.13, 1.0);
uniform vec4 r_lichen : source_color = vec4(0.55, 0.58, 0.42, 1.0);

// textured ground (mode 3): four tiling layers blended by noise masks, with
// large-scale colour variation and a second, rotated sampling of every layer so
// no repeat shows. Point sampled, 256 px layers at a PS1 texel density.
uniform sampler2D tex_a : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_b : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_c : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_d : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint_a : source_color = vec4(1.0);
uniform vec4 tint_b : source_color = vec4(1.0);
uniform vec4 tint_c : source_color = vec4(1.0);
uniform vec4 tint_d : source_color = vec4(1.0);
uniform sampler2D noise_a : filter_linear, repeat_enable;
uniform sampler2D noise_b : filter_linear, repeat_enable;
uniform float tile_m = 3.2;
// how much of the field each layer takes: B (second ground), C (bare soil), D (gravel)
uniform vec3 mix_bcd = vec3(0.45, 0.3, 0.12);
uniform vec4 warm : source_color = vec4(1.08, 1.0, 0.86, 1.0);

#include "res://shaders/ps1.gdshaderinc"

varying vec3 world_pos;
varying vec3 world_normal;

float hash1(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash1(i), hash1(i + vec3(1, 0, 0)), f.x), mix(hash1(i + vec3(0, 1, 0)), hash1(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash1(i + vec3(0, 0, 1)), hash1(i + vec3(1, 0, 1)), f.x), mix(hash1(i + vec3(0, 1, 1)), hash1(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 x) {
	return vnoise(x) * 0.55 + vnoise(x * 2.03) * 0.3 + vnoise(x * 4.1) * 0.15;
}

// Worley noise: (distance to nearest feature, to second nearest, nearest cell id)
vec3 worley(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	float d1 = 9.0;
	float d2 = 9.0;
	float id = 0.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int xx = -1; xx <= 1; xx++) {
				vec3 g = vec3(float(xx), float(y), float(z));
				vec3 o = vec3(hash1(i + g), hash1(i + g + 19.1), hash1(i + g + 47.7));
				float d = length(g + o - f);
				if (d < d1) {
					d2 = d1;
					d1 = d;
					id = hash1(i + g + 3.3);
				} else if (d < d2) {
					d2 = d;
				}
			}
		}
	}
	return vec3(d1, d2, id);
}

vec3 ground_colour(vec3 wp, float litter) {
	vec2 p = ps1_snap_m(wp.xz);
	// patch size picked per region: 1, 2, 3 or 4 times the base size
	float region = vnoise(vec3(p / (patch_m * 9.0), 0.0));
	float size = patch_m * (1.0 + floor(clamp(region, 0.0, 0.999) * 4.0));
	float v = fbm(vec3(p / size, 7.0 + size));
	vec3 c = g_lush.rgb;
	// hard edges between kinds of ground
	if (v < 0.43) { c = g_dark.rgb; }
	else if (v > 0.63) { c = g_bare.rgb; }
	else if (v > 0.57) { c = g_dry.rgb; }
	// small clumps and per-texel grain
	float clump = vnoise(vec3(p * 1.7, 3.0));
	c *= clump > 0.62 ? 1.1 : (clump < 0.3 ? 0.9 : 1.0);
	c *= 0.9 + hash1(vec3(floor(p * max(ps1_texel_m, 8.0)), 1.0)) * 0.2;
	// leaf litter under trees, in ragged clumps rather than a soft ring
	if (litter > 0.0 && litter > vnoise(vec3(p * 0.9, 11.0)) * 0.8 + 0.1) {
		c = g_litter.rgb * (0.85 + hash1(vec3(floor(p * 6.0), 5.0)) * 0.3);
	}
	return c;
}

vec3 rock_colour(vec3 wp, vec3 n) {
	vec3 p = ps1_snap_m3(wp);
	// zones of different stone, a few metres across, with ragged borders
	vec3 zp = p / 5.0 + vec3(fbm(p * 0.35), fbm(p * 0.35 + 9.0), fbm(p * 0.35 + 21.0)) * 0.8;
	vec3 zone = worley(zp);
	float zid = zone.z;
	vec3 base = zid < 0.4 ? r_a.rgb : (zid < 0.72 ? r_b.rgb : r_c.rgb);
	base *= 0.88 + fract(zid * 7.13) * 0.24;
	vec3 c = base;
	bool bedded = fract(zid * 3.71) < 0.55;
	if (bedded) {
		// bedding: bands of varying thickness and colour, dipping slightly,
		// fading out where the mask is low
		float dip = p.x * (fract(zid * 11.3) - 0.5) * 0.3 + p.z * (fract(zid * 5.9) - 0.5) * 0.3;
		float t = p.y + dip + fbm(p * 0.6) * 0.5;
		float thick = mix(0.12, 0.7, vnoise(vec3(floor(t * 1.3), zid * 50.0, 0.0)));
		float band = floor(t / thick);
		float bh = hash1(vec3(band, zid * 31.0, 2.0));
		vec3 bc = bh < 0.3 ? base * 0.72 : (bh < 0.55 ? base * 1.12 : (bh < 0.7 ? mix(base, r_b.rgb, 0.6) : base));
		float mask = smoothstep(0.35, 0.55, vnoise(p * 0.25 + 4.0));
		c = mix(c, bc, mask);
	} else {
		// massive rock broken by joints into blocks of slightly different tint
		vec3 j = worley(p / 1.4 + vec3(0.0, fbm(p) * 0.3, 0.0));
		c *= 0.86 + j.z * 0.28;
		if (j.y - j.x < 0.035) {
			c *= 0.62;
		}
	}
	// iron-oxide staining, strongest in patches near zone edges
	float edge = zone.y - zone.x;
	if (fbm(p * 0.7 + 13.0) + (0.25 - min(edge, 0.25)) > 0.78) {
		c = mix(c, r_stain.rgb, 0.42);
	}
	// dark varnish streaks running down the faces
	float streak = vnoise(vec3(p.x * 2.6, p.y * 0.12, p.z * 2.6));
	if (streak > 0.7 && abs(n.y) < 0.6) {
		c = mix(c, r_varnish.rgb, 0.55);
	}
	// lichen on faces that look up
	if (n.y > 0.45 && vnoise(p * 3.6 + 31.0) > 0.8 && vnoise(p * 0.5 + 8.0) > 0.45) {
		c = mix(c, r_lichen.rgb, 0.6);
	}
	c *= 0.9 + hash1(floor(p * max(ps1_texel_m, 8.0))) * 0.2;
	return c;
}

vec3 layer_sample(sampler2D t, vec2 p, float n) {
	vec3 a = texture(t, p / tile_m).rgb;
	// a second look at the same layer, rotated and scaled, where noise says so
	vec2 q = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80)) * p * 0.57 + vec2(17.3, 5.1);
	vec3 b = texture(t, q / tile_m).rgb;
	return mix(a, b, smoothstep(0.35, 0.65, n));
}

vec3 textured_ground(vec3 wp, float litter) {
	vec2 p = ps1_snap_m(wp.xz);
	float big = texture(noise_a, p / 90.0).r;
	float mid = texture(noise_b, p / 31.0 + 0.21).r;
	float small = texture(noise_a, p / 7.5 + 0.63).r;
	float fine = texture(noise_b, p / 2.3).r;
	float pick = texture(noise_a, p / 14.0 + 0.4).r;
	vec3 c = layer_sample(tex_a, p, pick) * tint_a.rgb;
	// a second ground (dry grass, say) in broad drifts
	float wb = smoothstep(1.0 - mix_bcd.x - 0.1, 1.0 - mix_bcd.x + 0.08, big * 0.65 + mid * 0.35);
	c = mix(c, layer_sample(tex_b, p, pick) * tint_b.rgb, wb);
	// bare soil where the noise runs high, ragged by the fine noise
	float wc = smoothstep(1.0 - mix_bcd.y - 0.04, 1.0 - mix_bcd.y + 0.05, mid * 0.6 + small * 0.4 + (fine - 0.5) * 0.12);
	c = mix(c, layer_sample(tex_c, p, pick) * tint_c.rgb, wc);
	// gravel in small patches inside the bare soil
	float wd = smoothstep(1.0 - mix_bcd.z - 0.03, 1.0 - mix_bcd.z + 0.04, small * 0.7 + fine * 0.3) * wc;
	c = mix(c, layer_sample(tex_d, p, pick) * tint_d.rgb, wd);
	// leaf litter under trees breaks the ground up into soil
	if (litter > 0.0 && litter > fine * 0.8 + 0.1) {
		c = mix(c, layer_sample(tex_c, p, pick) * tint_c.rgb * 0.8, 0.85);
	}
	// broad variation of brightness and warmth so large areas never look flat
	c *= mix(0.8, 1.2, texture(noise_b, p / 140.0 + 0.5).r);
	c = mix(c, c * warm.rgb, texture(noise_a, p / 75.0 + 0.8).r);
	return c;
}

// textured rock (mode 4): four stone textures, triplanar, in zones a few metres
// across with noise-ragged borders, darkened in crevices and mossy on top.
vec3 tri(sampler2D t, vec3 p, vec3 w) {
	return texture(t, p.zy / tile_m).rgb * w.x + texture(t, p.xz / tile_m).rgb * w.y + texture(t, p.xy / tile_m).rgb * w.z;
}

vec3 textured_rock(vec3 wp, vec3 n) {
	vec3 p = ps1_snap_m3(wp);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	// zones of stone; the borders are bent by two scales of noise
	vec2 zq = p.xz / 6.0 + p.y / 5.0 + vec2(texture(noise_a, p.xz / 23.0).r, texture(noise_b, p.zy / 19.0).r) * 1.4;
	float z = texture(noise_b, zq / 3.0).r;
	float m1 = smoothstep(0.38, 0.5, z);
	float m2 = smoothstep(0.55, 0.66, z + (texture(noise_a, p.xz / 5.0 + p.y / 4.0).r - 0.5) * 0.25);
	float m3 = smoothstep(0.7, 0.8, texture(noise_a, p.xz / 11.0 + p.y / 7.0 + 0.3).r);
	vec3 c = tri(tex_a, p, w) * tint_a.rgb;
	c = mix(c, tri(tex_b, p, w) * tint_b.rgb, m1);
	c = mix(c, tri(tex_c, p, w) * tint_c.rgb, m2);
	c = mix(c, tri(tex_d, p, w) * tint_d.rgb, m3);
	// broad light/dark drifts so no big face is one tone
	c *= mix(0.78, 1.18, texture(noise_b, p.xz / 37.0 + p.y / 13.0).r);
	// moss and lichen on faces that look up, in ragged patches
	float moss = smoothstep(0.55, 0.7, texture(noise_a, p.xz / 3.1).r) * smoothstep(0.35, 0.8, n.y);
	c = mix(c, r_lichen.rgb * 0.8, moss * 0.55);
	return c;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	PS1_VERTEX(UV)
}

void fragment() {
	vec3 c;
	if (proj_mode == 1) {
		c = ground_colour(world_pos, use_vertex_color ? COLOR.a : 0.0);
		if (use_vertex_color) {
			c *= COLOR.rgb;
		}
	} else if (proj_mode == 3) {
		c = textured_ground(world_pos, use_vertex_color ? COLOR.a : 0.0);
		if (use_vertex_color) {
			c *= COLOR.rgb;
		}
	} else if (proj_mode == 4) {
		c = textured_rock(world_pos, normalize(world_normal));
		if (use_vertex_color) {
			c *= COLOR.rgb;
		}
	} else if (proj_mode == 2) {
		c = rock_colour(world_pos, normalize(world_normal));
		if (use_vertex_color) {
			c *= COLOR.rgb;
		}
	} else {
		c = ps1_texture(detail_tex, UV, uv_per_m).rgb;
		if (use_vertex_color) {
			c *= COLOR.rgb;
		}
	}
	c *= tint.rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(g), c, saturation);
}
