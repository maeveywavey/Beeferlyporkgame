// Pixel textures shared by every 3D shader. Driven by global shader
// parameters (project.godot [shader_globals]) set from the Pixel textures
// setting:
//   ps1_snap     vertex grid across the screen width (0 = off, as every
//                setting now leaves it: only textures are pixelated)
//   ps1_texel_m  texels per metre of surface (0 = off). Every surface uses
//                the same texel size: ground, rock, bark, cards and people.
//   ps1_affine   0..1 blend towards affine texture mapping on UV-mapped
//                models (never on world-projected ground and rock)

global uniform float ps1_snap;
global uniform float ps1_texel_m;
global uniform float ps1_affine;

varying vec3 ps1_uvw;

// Snapped clip-space position of a vertex. snap_mult > 1 snaps to a finer
// grid (characters use 2.5, so their silhouettes keep their shape).
vec4 ps1_position(mat4 projection_m, mat4 modelview, vec3 vertex, float smul) {
	vec4 clip = projection_m * modelview * vec4(vertex, 1.0);
	if (ps1_snap > 0.0) {
		vec2 grid = vec2(ps1_snap, ps1_snap * 0.5625) * 0.5 * smul;
		vec2 ndc = clip.xy / clip.w;
		ndc = round(ndc * grid) / grid;
		clip.xy = ndc * clip.w;
	}
	return clip;
}

// Use at the end of vertex(): snaps the vertex on screen and records the
// affine texture coordinates.
#define PS1_VERTEX(uv) POSITION = ps1_position(PROJECTION_MATRIX, MODELVIEW_MATRIX, VERTEX, 1.0); ps1_uvw = vec3((uv) * POSITION.w, POSITION.w);
#define PS1_VERTEX_S(uv, m) POSITION = ps1_position(PROJECTION_MATRIX, MODELVIEW_MATRIX, VERTEX, m); ps1_uvw = vec3((uv) * POSITION.w, POSITION.w);

// Snap a position given in metres to the centre of its texel.
vec2 ps1_snap_m(vec2 p) {
	if (ps1_texel_m <= 0.0) {
		return p;
	}
	return (floor(p * ps1_texel_m) + 0.5) / ps1_texel_m;
}

vec3 ps1_snap_m3(vec3 p) {
	if (ps1_texel_m <= 0.0) {
		return p;
	}
	return (floor(p * ps1_texel_m) + 0.5) / ps1_texel_m;
}

// Sample a UV-mapped texture so that its texels are the same size in the world
// as everyone else's. uv_per_m is how many UV units span one metre of this
// surface (measured from the mesh when the material is made).
vec4 ps1_texture(sampler2D tex, vec2 uv, float upm) {
	vec2 u = mix(uv, ps1_uvw.xy / max(ps1_uvw.z, 1e-5), ps1_affine);
	if (ps1_texel_m > 0.0 && upm > 0.0) {
		float grid = ps1_texel_m / upm;
		u = (floor(u * grid) + 0.5) / grid;
		return textureLod(tex, u, 0.0);
	}
	return texture(tex, u);
}

// The same for surfaces whose two UV directions differ in scale (cards).
vec4 ps1_texture2(sampler2D tex, vec2 uv, vec2 upm) {
	vec2 u = mix(uv, ps1_uvw.xy / max(ps1_uvw.z, 1e-5), ps1_affine);
	if (ps1_texel_m > 0.0 && upm.x > 0.0) {
		vec2 grid = ps1_texel_m / upm;
		u = (floor(u * grid) + 0.5) / grid;
		return textureLod(tex, u, 0.0);
	}
	return texture(tex, u);
}
