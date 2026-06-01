shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float alpha = color.a;
	
	vec2 size = 1.0 / vec2(textureSize(TEXTURE, 0));
	float border = 0.0;
	
	border = max(border, texture(TEXTURE, UV + vec2(-1.0, -1.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(0.0, -1.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(1.0, -1.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(-1.0, 0.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(1.0, 0.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(-1.0, 1.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(0.0, 1.0) * size * outline_width).a);
	border = max(border, texture(TEXTURE, UV + vec2(1.0, 1.0) * size * outline_width).a);
	
	float borda = border - alpha;
	
	COLOR = mix(color, outline_color, borda);
}