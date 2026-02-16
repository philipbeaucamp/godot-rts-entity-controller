shader_type spatial;
render_mode unshaded;

uniform sampler2D spin_texture;
uniform vec4 color : source_color;
uniform bool clockwise = true;
uniform float speed : hint_range(0.0, 2.0) = 1.0;

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
			vec2(cos(angle), sin(angle)));

    uv -= pivot;
    uv = uv * rotation;
    uv += pivot;
    return uv;
}

void fragment()
{
	float direction = clockwise ? 1.0 : -1.0;
	vec2 rotated_uv = rotate(UV, vec2(0.5), TIME * speed * direction);
	vec4 rst = texture(spin_texture, rotated_uv);

	ALBEDO = rst.r * color.rgb;
	float fade = step(0.0, rotated_uv.x) * step(rotated_uv.x, 1.0) *
             step(0.0, rotated_uv.y) * step(rotated_uv.y, 1.0);
	ALPHA = rst.a * fade;
}