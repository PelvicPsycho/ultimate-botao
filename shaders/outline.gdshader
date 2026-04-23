shader_type spatial;

render_mode unshaded, cull_front, blend_mix;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 5.0) = 1.0;
uniform float outline_softness  : hint_range(0.0, 1.0) = 0.2;

varying float rim_factor;

void vertex() {
    // posição em view space
    vec3 view_pos = (VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // normal em view space
    vec3 view_normal = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

    // direção para a câmera (sempre +Z no view space)
    vec3 view_to_cam = vec3(0.0, 0.0, -1.0);

    // rim para suavizar a borda
    rim_factor = 1.0 - abs(dot(view_normal, view_to_cam));

    // extrusão estilo genshin (constante pela câmera)
    view_pos += view_normal * outline_thickness * 0.01;

    // voltar para clip space
    POSITION = PROJECTION_MATRIX * vec4(view_pos, 1.0);
}

void fragment() {
    float alpha = smoothstep(1.0 - outline_softness, 1.0, rim_factor);
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a * alpha;
}