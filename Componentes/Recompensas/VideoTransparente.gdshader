shader_type canvas_item;

// Configurações do Chroma (Alvo: Preto)
uniform vec4 chroma_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float chroma_sensitivity : hint_range(0.0, 1.0) = 0.2;
uniform float chroma_tolerance : hint_range(0.0, 1.0) = 0.05;

// Limiar da Máscara: diz o que é considerado "fora" do baú
uniform float mask_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    // 1. Divide o UV para o formato Horizontal Stack (hstack)
    vec2 color_uv = vec2(UV.x * 0.5, UV.y);
    vec4 color_tex = texture(TEXTURE, color_uv);
    
    vec2 mask_uv = vec2(UV.x * 0.5 + 0.5, UV.y);
    vec4 mask_tex = texture(TEXTURE, mask_uv);
    
    // 2. Calcula o Chroma Key isolado para o fundo
    float chroma_diff = distance(color_tex.rgb, chroma_color.rgb);
    float chroma_alpha = smoothstep(chroma_sensitivity, chroma_sensitivity + chroma_tolerance, chroma_diff);
    
    // O Alpha padrão assume o valor da própria máscara Luma
    float final_alpha = mask_tex.r;
    
    // 3. A REGRA DE OURO DA PROTEÇÃO:
    // Se o pixel na máscara for menor que o limite (ou seja, é a ÁREA EXTERNA)
    if (mask_tex.r < mask_threshold) {
        // Fora da máscara, quem manda é o Chroma Key para limpar o fundo preto
        final_alpha = chroma_alpha;
    } 
    // Se for maior (ÁREA INTERNA), ele ignora o Chroma Key e mantém a máscara pura.
    
    COLOR = vec4(color_tex.rgb, color_tex.a * final_alpha);
}