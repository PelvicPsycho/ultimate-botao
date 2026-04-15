shader_type spatial;

render_mode blend_mix, cull_front, unshaded;

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size = 0.03;

void vertex() {
	VERTEX += NORMAL * outline_size;
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}