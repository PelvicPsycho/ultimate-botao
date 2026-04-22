shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D diffuse_curve : repeat_disable;
uniform int band_count = 4;
uniform float light_min = 0.15;
uniform float light_max = 0.85;

void fragment() {
	float t = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	t = clamp((t - light_min) / max(light_max - light_min, 0.0001), 0.0, 1.0);

	float bands = max(float(band_count), 2.0);
	float band_t = floor(t * bands) / (bands - 1.0);
	band_t = clamp(band_t, 0.0, 1.0);

	vec3 grad = texture(diffuse_curve, vec2(band_t, 0.5)).rgb;

	if (length(grad) < 0.001) {
		grad = vec3(band_t);
	}

	ALBEDO = grad;
}