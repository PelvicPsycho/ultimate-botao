shader_type canvas_item;

// --- Bitcrush / Pixelate Controls ---
uniform float pixel_size : hint_range(1.0, 64.0) = 4.0;

// --- Drop Shadow Controls ---
uniform int dist = 4;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float angle : hint_range(0.0, 360.0) = 90.0;

// --- Sprite Tint / Hue Controls ---
uniform vec4 sprite_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Overlay Controls ---
uniform sampler2D overlay_texture : source_color, filter_nearest;
uniform float overlay_mix_amount : hint_range(0.0, 1.0) = 1.0;

// --- Stretch Deformation (drag feedback) ---
uniform vec2 stretch_direction = vec2(0.0, 1.0);
uniform float stretch_amount : hint_range(0.0, 1.0) = 0.0;

// Varyings to pass safe, mesh-expanded coordinates from vertex to fragment
varying vec2 main_uv;
varying vec2 shadow_uv;

void vertex() {
	// 1. Expand the sprite boundaries so the shadow doesn't get clipped
	vec2 uv_offset = TEXTURE_PIXEL_SIZE * float(dist * 2);
	vec2 uv_half = uv_offset * 0.5;
	vec2 uv_dist = uv_offset + 1.0;
	
	// 2. Rotate the shadow direction safely based on object transform
	vec2 shadow_direction = (vec4(cos(radians(angle)), sin(radians(angle)), 0.0, 1.0) * MODEL_MATRIX).xy;
	
	// 3. Stretch vertices outward
	VERTEX *= uv_dist;
	
	// 4. Apply drag-stretch deformation along stretch_direction (no rotation)
	if (length(stretch_direction) > 0.001 && stretch_amount > 0.001) {
		vec2 dir = normalize(stretch_direction);
		float along_factor = stretch_amount * 0.18;
		float compress_factor = stretch_amount * 0.12;
		float along = dot(VERTEX, dir);
		VERTEX = VERTEX * (1.0 - compress_factor) + dir * along * (along_factor + compress_factor);
	}
	
	// 5. Pass adjusted UV coordinates down to the fragment step
	main_uv = UV * uv_dist - uv_half;
	shadow_uv = main_uv - shadow_direction * uv_half;
}

void fragment() {
	// Get texture size for pixelation math
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	
	// --- Pixelate Coordinates ---
	// Round both UV sets into steps to "bitcrush" both layers uniformly
	vec2 crushed_main_uv = round(main_uv * (tex_size / pixel_size)) / (tex_size / pixel_size);
	vec2 crushed_shadow_uv = round(shadow_uv * (tex_size / pixel_size)) / (tex_size / pixel_size);
	
	// --- Shadow Pass ---
	// Sample alpha channel using crushed coordinates and create strict boundary clipping
	float shadow_amt = texture(TEXTURE, crushed_shadow_uv).a
		* step(-1.0, -crushed_shadow_uv.x)
		* step(-1.0, -crushed_shadow_uv.y)
		* step(0.0, crushed_shadow_uv.x)
		* step(0.0, crushed_shadow_uv.y);
	
	// Base color output starts as the shadow color
	COLOR = shadow_color * shadow_amt;
	
	// --- Main Sprite Pass ---
	// Sample main texture with crushed coordinates and create boundary clipping
	vec4 main_color = texture(TEXTURE, crushed_main_uv)
		* step(-1.0, -crushed_main_uv.x)
		* step(-1.0, -crushed_main_uv.y)
		* step(0.0, crushed_main_uv.x)
		* step(0.0, crushed_main_uv.y);
		
	// Apply the custom sprite tint uniform directly to the RGB channels
	main_color.rgb *= sprite_tint.rgb;
	
	// --- Overlay Multiply Pass ---
	// 1. Sample the overlay texture using the exact same crushed main coordinates
	vec4 overlay_sample = texture(overlay_texture, crushed_main_uv);
	
	// 2. Perform Multiply math: (Base Sprite * Overlay Color)
	vec3 multiplied_rgb = main_color.rgb * overlay_sample.rgb;
	
	// 3. Blend the multiply result back onto the sprite based on the overlay's transparency
	//    This prevents transparent empty space in the overlay from turning black
	vec3 overlay_blend = mix(main_color.rgb, multiplied_rgb, overlay_sample.a);
	
	// 4. Mix between the clean sprite and the multiplied sprite using the global control slider
	main_color.rgb = mix(main_color.rgb, overlay_blend, overlay_mix_amount);
	
	// --- Composition / Layering ---
	// Darken the overlap section where the sprite sits perfectly on top of its shadow
	COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), main_color.a);

	// Stamp the final blended, tinted, pixelated sprite over the top
	COLOR += main_color * main_color.a;
}
