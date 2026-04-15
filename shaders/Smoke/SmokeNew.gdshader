shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_disabled, diffuse_toon, specular_toon;

uniform vec2 TexturScale = vec2(1.000000, 1.000000);
uniform sampler2D Disolver_texture2 : source_color;
uniform sampler2D tex_lgt_6 : source_color;
uniform float Light_attenuation = 1.3;
uniform float Shadow_roundness = 1.0;
uniform sampler2D Color_1D_Gradient : source_color, hint_default_black;



void fragment() {
// ColorConstant:8

	vec4 n_out8p0 = vec4(0.000000, 0.000000, 0.000000, 1.000000);


// Vector2Parameter:5
	vec2 n_out5p0 = TexturScale;


// UVFunc:4
	vec2 n_in4p2 = vec2(0.00000, 0.00000);
	vec2 n_out4p0 = (UV - n_in4p2) * n_out5p0 + n_in4p2;


	vec4 n_out3p0;
// Texture2D:3
	n_out3p0 = texture(Disolver_texture2, n_out4p0);
	float n_out3p1 = n_out3p0.r;


// Input:7
	vec4 n_out7p0 = COLOR;
	float n_out7p4 = n_out7p0.a;


// Output:0
	ALBEDO = vec3(n_out8p0.xyz);
	ALPHA = n_out3p1;
	EMISSION = vec3(n_out7p0.xyz);
	ALPHA_SCISSOR_THRESHOLD = n_out7p4;


}

void light() {
// Input:2
	vec3 n_out2p0 = LIGHT;
	float dot_result = dot(NORMAL, LIGHT);
float add_some_math = (clamp(dot_result, -0.90, 0.90) + 1.0)*0.47*Light_attenuation;
	float fresnel = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), Shadow_roundness);
	float round_cell_shade = clamp(add_some_math,0.04, 0.98) * fresnel;
	vec4 color_1D_gradient = texture(Color_1D_Gradient, vec2(round_cell_shade));
	DIFFUSE_LIGHT = clamp(LIGHT_COLOR * vec3(color_1D_gradient.xyz), vec3(0), vec3(1));


// Input:3
	vec3 n_out3p0 = NORMAL;


// DotProduct:4
	float n_out4p0 = dot(n_out2p0, n_out3p0);


	float n_out5p0;
// Remap:5
	float n_in5p1 = -1.00000;
	float n_in5p2 = 1.00000;
	float n_in5p3 = 0.00000;
	float n_in5p4 = 1.00000;
	{
		float __input_range = n_in5p2 - n_in5p1;
		float __output_range = n_in5p4 - n_in5p3;
		n_out5p0 = n_in5p3 + __output_range * ((n_out4p0 - n_in5p1) / __input_range);
	}


// Texture2D:6
	vec4 n_out6p0 = texture(tex_lgt_6, vec2(n_out5p0));


// Output:0
	DIFFUSE_LIGHT = vec3(n_out6p0.xyz);


}
