shader_type canvas_item;
render_mode unshaded;

instance uniform float glitch = 0.0;
instance uniform float shift_glitch = 0.0;
uniform sampler2D shift_glitch_texture: filter_nearest;
uniform sampler2D screen_texture: repeat_enable, filter_nearest, hint_screen_texture;

void fragment() {
	float glitch_scale = glitch / 500.0;
	vec2 screen_uv = SCREEN_UV + (texture(shift_glitch_texture, UV).xy - vec2(0.5)) * shift_glitch;
	COLOR.r = textureLod(screen_texture, vec2(screen_uv.x - glitch_scale, screen_uv.y), 0.0).r;
	COLOR.g = textureLod(screen_texture, screen_uv, 0.0).g;
	COLOR.b = textureLod(screen_texture, vec2(screen_uv.x + glitch_scale, screen_uv.y), 0.0).b;
}
