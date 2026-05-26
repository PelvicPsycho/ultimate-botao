shader_type canvas_item;

uniform float speedMult = 0.1;

void vertex() {
	UV.x += TIME * speedMult;
}