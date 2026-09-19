shader_type spatial;

render_mode blend_mix, depth_prepass_alpha, cull_disabled;

uniform vec3 shallow_color : source_color = vec3(0.20, 0.58, 0.88);
uniform vec3 deep_color : source_color = vec3(0.04, 0.30, 0.55);
uniform vec3 highlight_color : source_color = vec3(0.55, 0.82, 1.0);

uniform float alpha_value : hint_range(0.0, 1.0) = 0.72;
uniform float wave_height : hint_range(0.0, 2.0) = 0.35;
uniform float wave_frequency : hint_range(0.1, 5.0) = 1.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 0.55;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.08;
uniform float specular_value : hint_range(0.0, 1.0) = 0.95;


void vertex() {
	float x = VERTEX.x;
	float z = VERTEX.z;

	float wave_1 = sin(
		x * wave_frequency + TIME * wave_speed
	);

	float wave_2 = cos(
		z * wave_frequency * 0.75 - TIME * wave_speed * 0.8
	);

	float wave_3 = sin(
		(x + z) * wave_frequency * 0.45
		+ TIME * wave_speed * 0.55
	);

	float wave_4 = cos(
		(x - z) * wave_frequency * 0.30
		- TIME * wave_speed * 0.35
	);

	VERTEX.y += (
		wave_1 * 0.40
		+ wave_2 * 0.30
		+ wave_3 * 0.20
		+ wave_4 * 0.10
	) * wave_height;
}


void fragment() {
	// Cria pequenas ondulações.
	float ripple_x = sin(
		UV.x * 85.0 + TIME * 1.3
	) * 0.035;

	float ripple_z = cos(
		UV.y * 72.0 - TIME * 1.1
	) * 0.035;

	vec3 distorted_normal = normalize(
		NORMAL + vec3(ripple_x, 0.0, ripple_z)
	);

	// Aumenta o reflexo nas laterais.
	float fresnel = pow(
		1.0 - clamp(
			dot(distorted_normal, normalize(VIEW)),
			0.0,
			1.0
		),
		3.0
	);

	vec3 water_color = mix(
		shallow_color,
		deep_color,
		fresnel
	);

	// Clareia a água vista por baixo.
	if (!FRONT_FACING) {
		water_color = mix(
			water_color,
			highlight_color,
			0.38
		);
	}

	// Adiciona pequenos brilhos.
	float shimmer = sin(
		UV.x * 120.0
		+ UV.y * 95.0
		+ TIME * 1.8
	);

	shimmer = smoothstep(
		0.72,
		1.0,
		shimmer
	);

	water_color += (
		highlight_color
		* shimmer
		* 0.12
	);

	ALBEDO = water_color;
	EMISSION = water_color * 0.10;
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;

	ALPHA = clamp(
		alpha_value + fresnel * 0.18,
		0.0,
		0.92
	);
}