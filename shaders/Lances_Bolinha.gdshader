shader_type canvas_item;

instance uniform vec4 cor_da_bolinha : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float espessura_contorno = 0.0;
uniform vec4 cor_do_contorno : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // 1. O Godot sabe o tamanho do pixel. Dividir 1 por ele nos dá a Largura e Altura exatas em pixels.
    vec2 tamanho_real = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // 2. Converte a posição do pixel atual para uma régua de pixels (ex: de 0 a 64px)
    vec2 coord_pixel = UV * tamanho_real;
    
    // 3. O centro exato da imagem
    vec2 centro = tamanho_real / 2.0;
    
    // 4. A SUA LÓGICA: Calcula o Raio Máximo (Largura dividida por 2)
    // Usamos o 'min' para garantir que, se o TextureRect for um retângulo, a bola não achate.
    float raio_maximo = min(tamanho_real.x, tamanho_real.y) / 2.0;
    
    // O raio onde a cor do time termina e o contorno branco começa
    float raio_interno = raio_maximo - espessura_contorno;
    
    // 5. Calcula a distância matemática do pixel atual até o centro
    float distancia_do_centro = distance(coord_pixel, centro);
    
    // 6. A MÁGICA DA BORDA LISA (Anti-Aliasing)
    // O 'smoothstep' cria um esfumaçado de 1 pixel exato nas beiradas para não ficar serrilhado/quadradão
    
    // Recorta as pontas do TextureRect deixando ele 100% redondo
    float transparencia_geral = 1.0 - smoothstep(raio_maximo - 1.0, raio_maximo, distancia_do_centro);
    
    // Define o que é o "meio" (cor do time) e o que é a "beirada" (branco)
    float mascara_da_borda = smoothstep(raio_interno - 1.0, raio_interno, distancia_do_centro);
    
    // Mistura as duas cores baseadas na máscara
    vec3 cor_final = mix(cor_da_bolinha.rgb, cor_do_contorno.rgb, mascara_da_borda);
    
    // 7. Aplica a cor e o recorte final
    COLOR = vec4(cor_final, transparencia_geral);
}