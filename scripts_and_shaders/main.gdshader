shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

uniform float depth_range: hint_range(0.1, 100.0) = 15.0;
uniform float depth_strength: hint_range(0.1, 10.0) = 0.4;

void vertex() { POSITION = vec4(VERTEX.xy, 1.0, 1.0); }

void fragment() {
	vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
  	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	view.xyz /= view.w;
  	float linear_depth = -view.z;
	float depth_map = linear_depth / depth_range;
	depth_map = clamp(depth_map, 0.0, 1.0);
	depth_map = pow(depth_map, depth_strength);
  	ALBEDO.rgb = mix(col, vec3(0.0), depth_map);
}