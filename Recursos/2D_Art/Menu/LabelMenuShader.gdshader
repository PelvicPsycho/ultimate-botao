shader_type canvas_item;

// Altura do arco (Negativo para cima, Positivo para baixo)
uniform float altura_arco : hint_range(-500.0, 500.0) = -100.0;
// Deve ser exatamente o 'Size.x' do seu Label no Inspector
uniform float largura_total = 600.0;
// Ajuste fino caso a fonte tenha espaços vazios nas laterais
uniform float compensacao_largura : hint_range(0.5, 1.5) = 1.0;

void vertex() {
	// 1. Centralizamos o X para que o 0 seja o meio exato do texto
	float x_local = VERTEX.x - (largura_total / 2.0);
	float w = largura_total * compensacao_largura;
	float h = abs(altura_arco);

	if (h > 0.01) {
		// 2. Geometria da Sagita: Calculamos o raio do círculo que passa 
		// pelas duas pontas e pelo pico da altura.
		float raio = (w * w) / (8.0 * h) + (h / 2.0);
		
		// 3. Calculamos o ângulo baseado na posição X centralizada
		float angulo = x_local / raio;
		
		// 4. Determinar o centro vertical do círculo imaginário
		// Se o arco é para cima, o centro está abaixo do texto.
		float direcao = sign(altura_arco); 
		float centro_y = raio * direcao;

		// 5. Transformação Polar (Mapeia o plano reto para o círculo)
		// VERTEX.y é mantido para que a espessura da letra acompanhe o raio
		float dist_do_centro = raio - (VERTEX.y * direcao);
		
		float final_x = sin(angulo) * dist_do_centro;
		float final_y = centro_y - cos(angulo) * dist_do_centro;

		VERTEX.x = final_x + (largura_total / 2.0);
		VERTEX.y = final_y;
	}
}