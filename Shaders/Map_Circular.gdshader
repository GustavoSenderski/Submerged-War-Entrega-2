shader_type canvas_item;

uniform float edge_darkness : hint_range(0.0, 1.0) = 0.55;
uniform float light_strength : hint_range(0.0, 1.0) = 0.35;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.22;


void fragment() {
	// Converte as coordenadas para o centro do mapa.
	vec2 p = UV * 2.0 - 1.0;
	float r2 = dot(p, p);

	// Remove a área externa do círculo.
	if (r2 > 1.0) {
		discard;
	}

	vec4 map_color = texture(TEXTURE, UV);
	float z = sqrt(1.0 - r2);

	// Simula a curvatura da esfera.
	vec3 normal = normalize(
		vec3(p.x, -p.y, z)
	);

	// Direção da iluminação.
	vec3 light_dir = normalize(
		vec3(-0.55, 0.65, 0.85)
	);

	float diffuse = max(
		dot(normal, light_dir),
		0.0
	);

	// Escurece as bordas do globo.
	float edge = pow(z, 0.75);

	float shade = mix(
		1.0 - edge_darkness,
		1.0,
		edge
	);

	// Cria um pequeno brilho na superfície.
	vec2 highlight_center = vec2(-0.28, -0.32);

	float highlight_distance = distance(
		p,
		highlight_center
	);

	float highlight = smoothstep(
		0.42,
		0.0,
		highlight_distance
	);

	vec3 final_rgb = map_color.rgb;

	final_rgb *= shade;

	final_rgb *= (
		0.78
		+ diffuse * light_strength
	);

	final_rgb += (
		vec3(1.0)
		* highlight
		* highlight_strength
	);

	COLOR = vec4(
		final_rgb,
		map_color.a
	);
}