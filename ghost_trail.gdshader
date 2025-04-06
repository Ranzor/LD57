shader_type canvas_item;

uniform float fade_amount : hint_range(0,1) = 0.9;
uniform vec4 trail_color : source_color = vec4(0.5,0.8,1.0,0.7);

void fragment()
{
	vec4 tex = texture(TEXTURE, UV);
	COLOR = mix(tex * trail_color, tex, fade_amount);
}