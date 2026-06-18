shader_type canvas_item;
render_mode unshaded;

uniform vec2 ground_global_position;
uniform vec2 ground_size;
uniform sampler2D mask_texture : hint_default_black;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 ground_uv = (world_pos - (ground_global_position - ground_size * 0.5)) / ground_size;

    if (ground_uv.x < 0.0 || ground_uv.x > 1.0 || ground_uv.y < 0.0 || ground_uv.y > 1.0) {
        discard;
    }

    vec4 mask = texture(mask_texture, ground_uv);
    if (mask.a < 0.1) {
        discard;
    }

    vec4 screen = textureLod(screen_texture, SCREEN_UV, 0.0);
    if (screen.a > 0.0001) {
        screen.rgb /= screen.a;
    }

    COLOR = screen;
}