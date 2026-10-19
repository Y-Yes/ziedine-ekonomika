// Real-time rotating Earth drawn on a flat quad (smooth at any frame rate).
// Textures are plain equirectangular maps (2:1), so they are easy to replace.
shader_type canvas_item;

uniform sampler2D tex_ok : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_bad : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_fire : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_lava : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_water : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_clouds : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_night : source_color, filter_linear_mipmap, repeat_enable;

uniform float pollution = 0.0;   // 0 clean, 0.5 grey, 1 burning
uniform float rot = 0.0;         // planet spin (radians)
uniform float cloud_rot = 0.0;   // extra cloud drift (radians)
uniform float tilt = 0.32;       // axis tilt towards the viewer
uniform float disk = 0.8;        // planet radius as a fraction of the quad half-size
uniform vec3 light_dir = vec3(-0.5, 0.42, 0.76);

vec3 tilt_x(vec3 v, float a) {
	float c = cos(a), s = sin(a);
	return vec3(v.x, c * v.y - s * v.z, s * v.y + c * v.z);
}

vec4 tex_grad(sampler2D t, vec2 uv_raw) {
	return textureGrad(t, uv_raw, dFdx(uv_raw), dFdy(uv_raw));
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) / disk;
	float r = length(p);
	float w_bad = clamp(pollution / 0.5, 0.0, 1.0);
	float w_fire = clamp((pollution - 0.5) / 0.4, 0.0, 1.0);
	vec3 atmo = mix(vec3(0.42, 0.72, 1.0), vec3(0.72, 0.62, 0.42), w_bad);
	atmo = mix(atmo, vec3(1.0, 0.45, 0.15), w_fire);
	vec3 L = normalize(light_dir);

	// outer atmosphere glow
	float glow = pow(clamp(1.0 - (r - 1.0) / 0.22, 0.0, 1.0), 2.4) * 0.75;
	vec4 outc = vec4(atmo, glow * step(1.0, r));

	if (r < 1.0) {
		vec3 n = vec3(p.x, -p.y, sqrt(1.0 - r * r));
		vec3 nt = tilt_x(n, tilt);
		float lon = atan(nt.x, nt.z);
		float lat = asin(clamp(nt.y, -1.0, 1.0));
		// continuous (non-wrapped) coordinate for derivatives, wrapped by the sampler
		vec2 uv = vec2((lon + rot) / TAU + 0.5, 0.5 - lat / PI);
		vec2 cuv = vec2((lon + rot + cloud_rot) / TAU + 0.5, 0.5 - lat / PI);

		vec3 c_ok = tex_grad(tex_ok, uv).rgb;
		vec3 c_bad = tex_grad(tex_bad, uv).rgb;
		vec3 c_fire = tex_grad(tex_fire, uv).rgb;
		vec3 col = mix(mix(c_ok, c_bad, w_bad), c_fire, w_fire);

		float cl = tex_grad(tex_clouds, cuv).r;
		vec3 ccol = mix(vec3(1.0), vec3(0.55, 0.5, 0.42), w_bad);
		ccol = mix(ccol, vec3(0.22, 0.17, 0.15), w_fire);
		col = mix(col, ccol, cl * mix(0.85, 1.0, w_bad));

		float ndl = dot(n, L);
		float day = smoothstep(-0.15, 0.35, ndl);
		vec3 lit = col * (0.07 + 1.3 * max(ndl, 0.0) + 0.1 * day);

		// sun glint on the oceans
		float water = tex_grad(tex_water, uv).r * (1.0 - cl);
		vec3 h = normalize(L + vec3(0.0, 0.0, 1.0));
		float spec = pow(max(dot(n, h), 0.0), 40.0) * water * 0.55 * (1.0 - w_bad);
		lit += vec3(spec);

		// city lights on the night side (fade out as the planet dies)
		vec3 night = tex_grad(tex_night, uv).rgb * (1.0 - day) * (1.0 - cl) * (1.0 - w_fire) * 1.4;
		lit += night * vec3(1.0, 0.85, 0.6);

		// glowing lava when burning (pulses)
		vec3 lava = tex_grad(tex_lava, uv).rgb;
		float pulse = 0.75 + 0.25 * sin(TIME * 2.5 + uv.x * 40.0);
		lit += lava * w_fire * 2.2 * pulse;

		// inner atmosphere rim
		float fres = pow(1.0 - n.z, 3.0);
		lit = mix(lit, atmo * (0.45 + 1.0 * day), fres * 0.8);

		float edge = smoothstep(1.0, 0.985, r);
		COLOR = mix(outc, vec4(lit, 1.0), edge);
	} else {
		COLOR = outc;
	}
}
