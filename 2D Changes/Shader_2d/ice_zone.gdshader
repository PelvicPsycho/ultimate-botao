shader_type canvas_item;

// Screen texture for refraction/distortion
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Noise texture for organic edge and cracks (assign a NoiseTexture2D in the editor)
uniform sampler2D noise_texture : repeat_enable;

uniform float radius : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float edge_softness : hint_range(0.0, 0.5, 0.001) = 0.05;
uniform float edge_roughness : hint_range(0.0, 0.5, 0.01) = 0.08;
uniform float transparency_center : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float refraction_strength : hint_range(0.0, 0.1, 0.001) = 0.015;
uniform float pulse_speed : hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float pulse_intensity : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float glow_intensity : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float crack_density : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float crack_width : hint_range(0.01, 0.2, 0.001) = 0.03;
uniform vec4 ice_color : source_color = vec4(0.72, 0.91, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.45, 0.85, 1.0, 1.0);

// Pseudo-random value for high frequency crack noise
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D simple value noise for high frequency cracks
float value_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for more detailed crack patterns
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * value_noise(uv * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

void fragment() {
    // Normalize UV coordinates so the ice zone is centered and circular
    vec2 centered_uv = UV - vec2(0.5);
    float distance_from_center = length(centered_uv);

    // Use the noise texture to distort the edge, creating an organic puddle-like shape
    float edge_noise = texture(noise_texture, UV + TIME * 0.02).r;
    float organic_radius = radius + (edge_noise - 0.5) * edge_roughness;

    // Create the main ice mask with smoothstep for smooth circular edges
    float ice_mask = 1.0 - smoothstep(organic_radius - edge_softness, organic_radius + edge_softness, distance_from_center);

    // Central transparency: more transparent in the center, stronger ice at the edges
    float edge_factor = smoothstep(0.0, organic_radius, distance_from_center);
    float center_alpha = 1.0 - (1.0 - edge_factor) * transparency_center;
    float alpha = ice_mask * center_alpha;

    // Refract the background using the noise texture as a distortion map
    vec2 noise_uv = UV + TIME * 0.03;
    vec2 distortion = (texture(noise_texture, noise_uv).rg - vec2(0.5)) * refraction_strength;

    // Background refraction using screen texture
    vec2 screen_uv = SCREEN_UV + distortion * ice_mask;
    vec3 background = texture(screen_texture, screen_uv).rgb;

    // High frequency noise for cracks inside the ice
    vec2 crack_uv = UV * 25.0 + TIME * 0.01;
    float crack_noise = fbm(crack_uv);
    // Invert and sharpen to create thin crack lines
    float crack = 1.0 - smoothstep(crack_width, crack_width + 0.02, abs(crack_noise - crack_density));
    crack *= ice_mask * edge_factor; // cracks more visible near edges

    // Pulsating blue glow on the ice edge
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * pulse_intensity + (1.0 - pulse_intensity);
    float glow = (1.0 - smoothstep(organic_radius - edge_softness * 2.0, organic_radius + edge_softness, distance_from_center));
    glow *= (1.0 - edge_factor) * pulse; // stronger near the edge, pulses with time

    // Combine ice color, refraction, cracks, and glow
    vec3 ice_tint = mix(background, ice_color.rgb, (1.0 - center_alpha) * 0.25 * ice_color.a);
    ice_tint = mix(ice_tint, vec3(0.15, 0.25, 0.35), crack * 0.75); // dark cracks
    ice_tint += glow_color.rgb * glow * glow_intensity;

    // Final output
    COLOR = vec4(ice_tint, alpha);
}