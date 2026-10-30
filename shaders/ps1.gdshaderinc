// PS1-style rendering shared by every 3D shader. Driven by global shader
// parameters (project.godot [shader_globals]) set from the Retro look setting:
//   ps1_snap    vertex grid across the screen width (0 = off); vertices snap
//               to it, so edges wobble as the camera moves
//   ps1_tex     texels across a texture (0 = off); textures are point-sampled
//               at this resolution
//   ps1_affine  0..1 blend towards affine (non-perspective) texture mapping

global uniform float ps1_snap;
global uniform float ps1_tex;
global uniform float ps1_affine;

varying vec3 ps1_uvw;

// Snapped clip-space position of a vertex.
vec4 ps1_position(mat4 projection_m, mat4 modelview, vec3 vertex) {
	vec4 clip = projection_m * modelview * vec4(vertex, 1.0);
	if (ps1_snap > 0.0) {
		vec2 grid = vec2(ps1_snap, ps1_snap * 0.5625) * 0.5;
		vec2 ndc = clip.xy / clip.w;
		ndc = round(ndc * grid) / grid;
		clip.xy = ndc * clip.w;
	}
	return clip;
}

// Use at the end of vertex(): snaps the vertex on screen and records the
// affine texture coordinates for ps1_uv().
#define PS1_VERTEX(uv) POSITION = ps1_position(PROJECTION_MATRIX, MODELVIEW_MATRIX, VERTEX); ps1_uvw = vec3((uv) * POSITION.w, POSITION.w);

// The texture coordinate to sample with: blended towards affine, then
// quantised to the PS1 texel grid.
vec2 ps1_uv(vec2 uv) {
	vec2 u = mix(uv, ps1_uvw.xy / max(ps1_uvw.z, 1e-5), ps1_affine);
	if (ps1_tex > 0.0) {
		u = (floor(u * ps1_tex) + 0.5) / ps1_tex;
	}
	return u;
}

vec4 ps1_texture(sampler2D tex, vec2 uv) {
	if (ps1_tex > 0.0) {
		return textureLod(tex, ps1_uv(uv), 0.0);
	}
	return texture(tex, mix(uv, ps1_uvw.xy / max(ps1_uvw.z, 1e-5), ps1_affine));
}
