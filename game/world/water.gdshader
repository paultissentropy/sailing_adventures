shader_type spatial;
// Eau plate stylisée : grandes taches douces et vaguelettes allongées en travers du vent.
// Le motif est en coordonnées monde et ne dérive que très lentement : l'eau sert de
// repère fixe pour sentir la vitesse et la trajectoire du bateau.

uniform vec3 deep_color : source_color = vec3(0.10, 0.42, 0.58);
uniform vec3 light_color : source_color = vec3(0.26, 0.64, 0.74);
uniform vec3 crest_color : source_color = vec3(0.92, 0.98, 1.0);
// Direction vers laquelle va l'air (x, z), unitaire.
uniform vec2 wind_flow = vec2(0.0, 1.0);
// Vitesse du vent (m/s).
uniform float wind_speed = 5.0;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Bruit de gradient (type Perlin), à peu près dans [0, 1].
float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = hash(i) * 6.2831853;
	float b = hash(i + vec2(1.0, 0.0)) * 6.2831853;
	float c = hash(i + vec2(0.0, 1.0)) * 6.2831853;
	float d = hash(i + vec2(1.0, 1.0)) * 6.2831853;
	float va = dot(vec2(cos(a), sin(a)), f);
	float vb = dot(vec2(cos(b), sin(b)), f - vec2(1.0, 0.0));
	float vc = dot(vec2(cos(c), sin(c)), f - vec2(0.0, 1.0));
	float vd = dot(vec2(cos(d), sin(d)), f - vec2(1.0, 1.0));
	return 0.5 + mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y);
}

// Vaguelettes : coordonnées (travers, sens du vent), allongées en travers du vent.
float ripples(vec2 q, float t) {
	float speed = 0.05 + wind_speed * 0.015;
	float r = gnoise(vec2(q.x * 0.22, q.y * 0.9 - t * speed));
	r += 0.5 * gnoise(vec2(q.x * 0.5 + 3.1, q.y * 1.9 - t * speed * 1.4));
	return r / 1.5;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float strength = clamp(wind_speed / 6.0, 0.15, 2.0);
	vec2 across = vec2(-wind_flow.y, wind_flow.x);
	vec2 q = vec2(dot(p, across), dot(p, wind_flow));

	float big = gnoise(p * 0.012) * 0.65 + gnoise(p * 0.04 + 7.0) * 0.35;
	float r = ripples(q, TIME);
	float crest = smoothstep(0.66 - 0.05 * strength, 0.8, r) * min(strength, 1.0);

	vec3 col = mix(deep_color, light_color, smoothstep(0.25, 0.8, big));
	col = mix(col, crest_color, crest * 0.35);
	ALBEDO = col;
	ROUGHNESS = 0.25;
	SPECULAR = 0.5;

	// Normales tirées des vaguelettes (différences finies).
	float e = 0.15;
	float dx = ripples(q + vec2(e, 0.0), TIME) - r;
	float dy = ripples(q + vec2(0.0, e), TIME) - r;
	vec2 slope = -vec2(dx, dy) / e * 0.06 * strength;
	vec2 g = across * slope.x + wind_flow * slope.y;
	vec3 n_world = normalize(vec3(g.x, 1.0, g.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
}
