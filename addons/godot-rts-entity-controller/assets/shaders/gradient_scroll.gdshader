shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_test_disabled;

uniform sampler2D gradient_texture : source_color;

uniform float flow_speed : hint_range(-2.0, 2.0) = 0.5;

uniform float emission_strength : hint_range(0.0, 5.0) = 1.0;
uniform vec4 emission_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 base_uv = UV;
	float v_animated = fract(base_uv.y - TIME * flow_speed);
	vec4 gradient_color = texture(gradient_texture, vec2(v_animated, base_uv.x));

	ALBEDO = gradient_color.rgb;
	ALPHA = gradient_color.a;

	float emission_value = length(gradient_color.rgb) * emission_strength;
	EMISSION = gradient_color.rgb * emission_tint.rgb * emission_value;
}
