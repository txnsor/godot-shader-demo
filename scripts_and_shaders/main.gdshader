shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

uniform sampler2D TEST_TEXTURE;

/// PREMADE CONVOLUTION KERNELS

uniform mat3 box_blur = mat3(vec3(0.333), vec3(0.333), vec3(0.333));
uniform mat3 sobel_x = mat3(vec3(-1.0, 0.0, 1.0), vec3(-2.0, 0.0, 2.0), vec3(-1.0, 0.0, 1.0));
uniform mat3 sobel_y = mat3(vec3(-1.0, -2.0, -1.0), vec3(0.0), vec3(1.0, 2.0, 1.0));
uniform mat3 gaussian = mat3(vec3(.0625, .125, .0625), vec3(.125, .25, .125), vec3(.0625, .125, .0625));
uniform mat3 laplacian = mat3(vec3(0.0, -1.0, 0.0), vec3(-1.0, 4.0, -1.0), vec3(0.0, -1.0, 0.0));

///


// Convolve a texture (row-major kernel because i hate column-major)
// in: tex (texture, i.e SCREEN_TEXTURE)
// in: uv (SCREEN_UV)
// in: px_size (1.0 / VIEWPORT_SIZE)
// in: step_size (pixel distance between samples)
// in: kernel (convolution kernel)
// out: pixel value of convolved texture at position (u, v).
vec4 convolve(sampler2D tex, vec2 uv, vec2 px_size, float step_size, mat3 kernel) {
	vec4 res = vec4(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			// each sample is some distance from the initial pixel uv
			// this distance is defined by the size of a pixel, i, j, and the step_size
			// clamp this to [0, 1] for edge case handling
			vec2 ix = step_size * px_size * vec2(float(i), float(j));
			vec2 sample_uv = clamp(uv + ix, vec2(0.0), vec2(1.0));
			// weighted addition here !!!!!
			vec4 val = kernel[j + 1][i + 1]*texture(tex, sample_uv);
			res += val;
		}
	}
	return res;
}

// Get a usable depth map normalized to be between 0 and 1 given a depth range and strength
// in: depth_range (distance from camera before cutoff)
// in: depth_strength (exponent that final depth map is raised to)
// in: uv (SCREEN_UV)
// in: inv_proj (INV_PROJECTION_MATRIX)
// out: depth map per pixel normalized between 0 and 1
float format_depth(float depth_range, float depth_strength, vec2 uv, mat4 inv_proj) {
	// get depth map and normalize it
	float depth = texture(DEPTH_TEXTURE, uv).x;
	// normalized device coordinates = ndc [-1, 1]
  	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
  	vec4 view = inv_proj * vec4(ndc, 1.0);
  	view.xyz /= view.w;
  	float linear_depth = -view.z;
	float depth_map = linear_depth / depth_range;
	depth_map = clamp(depth_map, 0.0, 1.0);
	depth_map = pow(depth_map, depth_strength);	
	return depth_map;
}

// generate a random num
// in: uv (SCREEN_UV)
// out: random float between 0 and 1
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// make the meshinstance follow the camera
void vertex() { POSITION = vec4(VERTEX.xy, 1.0, 1.0); }

void fragment() {
	// read color......
	vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	// get depth and process it to be usable
	float depth = format_depth(20.0, 1.5, SCREEN_UV, INV_PROJECTION_MATRIX);
	// convolution example
	// NOTE: because of godot, you can only currently choose one texture to convolve...
	vec3 edges = convolve(SCREEN_TEXTURE, SCREEN_UV, 1.0 / VIEWPORT_SIZE, 5.0, laplacian).rgb;
	// TIME is built in!
	float noise = random(SCREEN_UV + TIME);
	
	// do literally anything here (or change the last three lines too!	
	// ...or, check out the WorldEnvironment node
	
	ALBEDO.rgb = col;
  	
}