shader_type spatial;
render_mode unshaded, cull_disabled, world_vertex_coords;

varying vec3 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	float flow = world_position.x * 0.74 - TIME * 1.9;
	float eddies = sin(world_position.z * 1.8 + sin(flow * 0.53) * 0.8);
	float streaks = smoothstep(0.86, 1.0, sin(flow + 2.1 * eddies));
	float falls = smoothstep(0.28, 0.78, abs(NORMAL.x));
	ALBEDO = mix(COLOR.rgb, vec3(0.69, 0.82, 0.73), streaks * 0.14 + falls * 0.42);
}
