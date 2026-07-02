shader_type canvas_item;

uniform float scroll_speed : hint_range(0, 2) = 0.05;
uniform float angle_degrees : hint_range(0, 360, 1) = 45.0;
uniform float repeat_x : hint_range(1, 50, 1) = 1;
uniform float repeat_y : hint_range(1, 50, 1) = 1;
uniform vec4 tint : source_color = vec4(1.0);

// Noise warp settings
uniform sampler2D noise_texture : repeat_enable;
uniform float warp_strength : hint_range(0, 0.5, 0.01) = 0.05;
uniform float warp_scale : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float warp_speed : hint_range(0, 2) = 0.1;

// Bitcrush settings
uniform bool enable_bitcrush = false;
uniform float pixel_size : hint_range(2, 254, 1) = 8.0;      // Block size (lower = bigger pixels)
uniform int color_depth : hint_range(2, 32, 1) = 8;        // Color levels per channel (lower = more crushed)
uniform bool crush_warp = true;                            // Also reduce warp resolution

// Dithering (optional, to smooth bitcrush artifacts)
uniform bool enable_dithering = false;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.5;

const float bayer_matrix[16] = float[](
    0.0,  8.0,  2.0, 10.0,
    12.0, 4.0, 14.0, 6.0,
    3.0, 11.0, 1.0,  9.0,
    15.0, 7.0, 13.0, 5.0
);

void fragment() {
	float angle_rad = radians(angle_degrees);
	vec2 direction = vec2(cos(angle_rad), sin(angle_rad));
	
	// --- Bitcrushed warp (optional: reduce resolution of the noise sampling) ---
	vec2 warp_uv = UV;
	if (enable_bitcrush && crush_warp) {
		// Quantize UV before warp sampling - creates chunky, blocky distortion
		warp_uv = floor(UV * pixel_size) / pixel_size;
	}
	
	vec2 noise_uv = warp_uv * warp_scale + TIME * warp_speed;
	vec4 noise = texture(noise_texture, noise_uv);
	
	// --- Displace UVs ---
	vec2 displaced_uv = warp_uv + (noise.rg * 2.0 - 1.0) * warp_strength;
	
	// --- Tiling and scrolling ---
	vec2 tiled_uv = displaced_uv * vec2(repeat_x, repeat_y);
	vec2 scrolling_uv = tiled_uv - TIME * scroll_speed * direction;
	
	// --- Bitcrushed texture sampling (creates pixel blocks) ---
	vec2 final_uv;
	if (enable_bitcrush) {
		// Quantize UVs for the final texture - creates visible pixel blocks
		final_uv = fract(floor(scrolling_uv * pixel_size) / pixel_size);
	} else {
		final_uv = fract(scrolling_uv);
	}
	
	vec4 tex_color = texture(TEXTURE, final_uv);
	vec4 final_color = tex_color * tint;
	
	// --- Bitcrush color depth (reduces color palette) ---
	if (enable_bitcrush) {
		float levels = float(color_depth);
		for (int i = 0; i < 3; i++) {
			final_color[i] = floor(final_color[i] * levels) / (levels - 1.0);
		}
	}
	
	// --- Dithering (apply after bitcrush to soften artifacts) ---
	if (enable_dithering) {
		vec2 pixel_pos = FRAGCOORD.xy;
		int x = int(mod(pixel_pos.x, 4.0));
		int y = int(mod(pixel_pos.y, 4.0));
		float threshold = bayer_matrix[y * 4 + x] / 16.0;
		
		float levels = float(color_depth);
		float strength = dither_strength;
		
		for (int i = 0; i < 3; i++) {
			float channel = final_color[i];
			float quantized = channel;
			float dithered = quantized + (threshold - 0.5) * strength;
			final_color[i] = clamp(floor(dithered * levels) / (levels - 1.0), 0.0, 1.0);
		}
	}
	
	COLOR = final_color;
}