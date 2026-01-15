shader_type canvas_item;

uniform float health : hint_range(0.0, 1.0);  // Health value between 0 and 1
uniform float border_width_y : hint_range(0.0,0.5,0.01);
uniform float border_width_x : hint_range(0.0,0.1,0.01);
uniform vec4 back_ground_color: source_color  = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 border_color: source_color  = vec4(0.0, 0.0, 0.0, 1.0);
void fragment() {
    //// Calculate the color for the health bar based on the health percentage
	vec2 uv = UV;
	
	float health_alpha = 1.0-step(health,uv.x);
    vec4 health_color = mix(vec4(1.0, 0.0, 0.0, health_alpha), vec4(.0, 1.0, 0.0, health_alpha), health);
	health_color = mix(health_color, back_ground_color, step(health_alpha, 0.0));
	
	//vec2 tex_size = vec2(1.0, 1.0);  // Assuming the default 1:1 aspect ratio (can be modified if using texture sampling)
    vec2 tex_size = vec2(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y); // To handle non-1:1 textures
  	uv /= tex_size;
	
    // Border (top & bottom)
    float border_mask = step(uv.y, border_width_y) + step(1.0 - border_width_y, uv.y);

    // Vertical separator lines at 25%, 50%, and 75%
    float separator_mask = step(abs(uv.x - 0.02), border_width_x) + 
                           step(abs(uv.x - 0.25), border_width_x) + 
   						   step(abs(uv.y - 0.01), border_width_y) + 
						   step(abs(uv.y - 0.99), border_width_y) + 
                           step(abs(uv.x - 0.50), border_width_x) + 
                           step(abs(uv.x - 0.75), border_width_x) + 
                           step(abs(uv.x - 0.98), border_width_x);
						
    // Mix health color and black overlay
    COLOR = mix(health_color, border_color, separator_mask);
}
