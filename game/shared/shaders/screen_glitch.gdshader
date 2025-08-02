shader_type canvas_item;
render_mode unshaded;

instance uniform float glitch = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;

void fragment() {
	float glitch_scale = glitch / 500.0;
	COLOR.r = textureLod(screen_texture, vec2(SCREEN_UV.x - glitch_scale, SCREEN_UV.y), 0.0).r;
	COLOR.g = textureLod(screen_texture, SCREEN_UV, 0.0).g;
	COLOR.b = textureLod(screen_texture, vec2(SCREEN_UV.x + glitch_scale, SCREEN_UV.y), 0.0).b;
}