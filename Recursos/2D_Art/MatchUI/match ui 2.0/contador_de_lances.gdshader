shader_type canvas_item;

// Define o quão "rigoroso" é o branco puro. 
// 1.0 exige que seja branco absoluto. 0.8 costuma ser ideal para pixel art ou imagens com anti-aliasing.
uniform float tolerancia_branco : hint_range(0.0, 1.0) = 0.8;

// Se ativado, preserva as sombras da arte original (tons de cinza/preto viram tons escuros da cor do time).
// Se desativado, pinta a área não-branca com uma cor sólida e chapada.
uniform bool manter_sombreamento = true;

void fragment() {
    // 1. A MAGIA: Lemos a cor do "modulate" que vem do seu GDScript ou do Inspector
    vec4 cor_do_modulate = COLOR; 
    
    // 2. Lemos a cor real original do seu arquivo PNG (intacta)
    vec4 cor_png = texture(TEXTURE, UV);
    
    // 3. Calculamos a luminosidade da arte original (o quão claro é o pixel)
    float brilho = dot(cor_png.rgb, vec3(0.299, 0.587, 0.114));
    
    // 4. Criamos uma máscara: 1.0 se for considerado Branco, 0.0 se for escuro/outra cor
    // Usamos smoothstep para que a borda entre o branco e a cor não fique serrilhada
    float mascara_branco = smoothstep(tolerancia_branco - 0.1, tolerancia_branco + 0.05, brilho);
    
    // 5. Preparamos a cor que vai substituir as áreas escuras
    vec3 cor_aplicada;
    if (manter_sombreamento) {
        // Multiplica a cor do time pelo brilho do PNG. 
        // Adicionamos +0.15 para que o preto absoluto não fique invisível, mas vire um tom escuro da cor do time.
        cor_aplicada = cor_do_modulate.rgb * (brilho + 0.15); 
    } else {
        // Pinta de forma chapada
        cor_aplicada = cor_do_modulate.rgb;
    }
    
    // 6. Misturamos as áreas: Se a máscara for 1, mantém o PNG original (branco). Se for 0, usa a cor do time.
    vec3 cor_final = mix(cor_aplicada, cor_png.rgb, mascara_branco);
    
    // 7. Saída final mantendo a transparência (Alpha) original do PNG e multiplicando pelo Alpha do modulate (pra permitir fade in/out)
    COLOR = vec4(cor_final, cor_png.a * cor_do_modulate.a);
}