shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    float alpha = texture(TEXTURE, UV).a;
    
    // Verifica os pixels vizinhos para detectar a borda
    float max_alpha = 0.0;
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
    max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
    
    // Calcula a borda: pixels vizinhos opacos onde o pixel atual é transparente
    float border = step(alpha, 0.5) * max_alpha;
    
    vec4 sprite_color = texture(TEXTURE, UV);
    
    // Se for borda, aplica a cor do contorno com alpha fixo (ignora o modulate do pai)
    if (border > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = sprite_color;
    }
}