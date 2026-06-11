shader_type canvas_item;

uniform sampler2D textura_infinita : repeat_enable;
uniform float velocidade_scroll = 0.05;

// Variáveis exportadas para o Inspector
uniform vec4 cor_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brilho : hint_range(0.0, 5.0) = 1.0;
uniform float nivel_cinza : hint_range(0.0, 1.0) = 0.0; // 0.0 é normal, 1.0 é 100% cinza

void fragment() {
    vec2 uv_deslocada = UV;
    uv_deslocada.x += TIME * velocidade_scroll;
    
    vec4 cor_final = texture(textura_infinita, uv_deslocada);
    
    // SE O PIXEL FOR QUASE TRANSPARENTE, DESTRÓI ELE!
    if (cor_final.a < 0.55) {
        discard; 
    }
    
    // 1. Aplica a nova cor e o brilho
    cor_final.rgb *= cor_tint.rgb * brilho;
    
    // 2. Calcula o tom de cinza (fórmula padrão de luminância)
    float cinza = dot(cor_final.rgb, vec3(0.299, 0.587, 0.114));
    
    // 3. Mistura a cor atual com a versão cinza baseada no controle do Inspector
    cor_final.rgb = mix(cor_final.rgb, vec3(cinza), nivel_cinza);
    
    // Retornado ao original, sem multiplicar pelo COLOR
    COLOR = cor_final;
}