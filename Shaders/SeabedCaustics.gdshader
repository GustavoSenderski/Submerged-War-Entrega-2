shader_type spatial;

uniform vec3 seabed_color : source_color = vec3(0.10, 0.22, 0.28);
uniform vec3 caustics_color : source_color = vec3(0.30, 0.72, 0.95);

uniform float caustics_strength : hint_range(0.0, 1.0) = 0.30;
uniform float caustics_scale : hint_range(1.0, 50.0) = 18.0;
uniform float caustics_speed : hint_range(0.0, 3.0) = 0.35;


void fragment() {
	// Define escala e movimento das cáusticas.
	vec2 p = UV * caustics_scale;

	float wave1 = sin(
		p.x + TIME * caustics_speed
	);

	float wave2 = sin(
		p.y * 1.3 - TIME * caustics_speed * 0.8
	);

	float wave3 = sin(
		(p.x + p.y) * 0.7
		+ TIME * caustics_speed * 0.6
	);

	// Combina as ondas para formar o padrão.
	float pattern = wave1 * wave2;
	pattern += wave3 * 0.5;

	pattern = smoothstep(
		0.45,
		1.0,
		pattern
	);

	vec3 final_color = (
		seabed_color
		+ caustics_color
		* pattern
		* caustics_strength
	);

	ALBEDO = final_color;
	ROUGHNESS = 0.8;
}