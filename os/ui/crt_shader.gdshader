shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scanline_count : hint_range(0, 1080) = 320.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.08;
uniform float noise_opacity : hint_range(0.0, 1.0) = 0.04;
uniform float distortion : hint_range(0.0, 0.1) = 0.01;
uniform float brightness : hint_range(0.5, 2.0) = 1.1;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Aberration chromatique légère
	float r = texture(screen_texture, uv + vec2(0.001, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(0.001, 0.0)).b;
	
	vec3 color = vec3(r, g, b);
	
	// Scanlines
	float scanline = sin(uv.y * scanline_count * 3.14159 * 2.0);
	color -= scanline * scanline_opacity;
	
	// Grainy noise
	float noise = (fract(sin(dot(uv + TIME * 0.1, vec2(12.9898,78.233))) * 43758.5453) - 0.5) * noise_opacity;
	color += noise;
	
	color *= brightness;
	
	COLOR = vec4(color, 1.0);
}
