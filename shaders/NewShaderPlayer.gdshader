shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_toon;

uniform sampler2D bw_gradient;
uniform sampler2D color_gradient;
uniform float cutoff : hint_range(0.0, 1.0) = 0.3;
uniform float intensity : hint_range(0.1, 3.0) = 1.2;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform int steps : hint_range(1, 10) = 1;

void light() {
    vec3 L = LIGHT;
    float raw = clamp(dot(NORMAL, L), 0.0, 1);

    float remap = smoothstep(cutoff, 1, raw);
    float toon_l = pow(remap, intensity);
	

   if (steps > 1) {
    toon_l = floor(toon_l * float(steps)) / float(steps);
}

    float bw_val = texture(bw_gradient, vec2(toon_l, 0.5)).r;
    vec3 col_val = texture(color_gradient, vec2(bw_val, 0.5)).rgb;

    float lum = dot(col_val, vec3(0.299, 0.587, 0.114));
    col_val = mix(vec3(lum), col_val, saturation);

    DIFFUSE_LIGHT += col_val * ATTENUATION * LIGHT_COLOR;
    SPECULAR_LIGHT = vec3(0.0);
}