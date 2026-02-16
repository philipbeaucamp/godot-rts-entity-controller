shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D texture_albedo; //the texture to scroll

uniform vec3 color : source_color = vec3(1.0,1.0,1.0); //color to blend albedo_texture with
uniform float blend_factor = 0.0; //factor of color blending

uniform vec2 motion = vec2(1.0,0.0); //scrolling direction
uniform float speed = 1.0; // Scrolling speed
uniform vec2 scale = vec2(1.0,1.0); //scale of texture
uniform vec2 offset = vec2(0.0,0.0); //offset of the texture

uniform float gap_size_x = 0.0; // how much gap (x-direction) between textures
uniform float gap_size_y = 0.0; // how much gap (y-direction) between textures

uniform float alpha_factor: hint_range(0.0,1.0) = 1.0;
uniform float texture_fade_distance_x : hint_range(0.0, 1.0) = 0.0; // The distance from the edges where fading starts
uniform float texture_fade_distance_y : hint_range(0.0, 1.0) = 0.0; // The distance from the edges where fading starts
uniform float mesh_fade_distance_x_start = 0.0; // The distance from the mesh edge in X direction (start)
uniform float mesh_fade_distance_y_start = 0.0; // The distance from the mesh edge in Y direction (start)
uniform float mesh_fade_distance_x_end = 0.0; // The distance from the mesh edge in X direction (end)
uniform float mesh_fade_distance_y_end  = 0.0; // The distance from the mesh edge in Y direction (end)

void fragment(){
	//Step 1. Albedo
	vec2 uv = UV * scale;
	uv += offset;
	uv -= motion * TIME * speed; //scroll in positive x/z direction

    vec2 tile_uv;
    tile_uv.x = mod(uv.x, 1.0 + gap_size_x); // Wrap X coordinate but include the gap
    tile_uv.y = mod(uv.y, 1.0 + gap_size_y);

    if (tile_uv.x > 1.0 || tile_uv.y > 1.0) {
        discard; // Skip rendering in the gap region
    }

	vec4 tex = texture(texture_albedo,tile_uv);
	ALBEDO = mix(tex.rgb,color,blend_factor);

	//Step 2. Alpha

    // Calculate how far the current UV is from the edge of the current tile
    float texture_edge_distance_x = min(tile_uv.x, 1.0 - tile_uv.x);
    float texture_edge_distance_y = min(tile_uv.y, 1.0 - tile_uv.y);

   // Calculate how far the current UV is from the edges of the mesh (not just the tile)
    float mesh_edge_distance_x = min(UV.x, 1.0 - UV.x);
    float mesh_edge_distance_y = min(UV.y, 1.0 - UV.y);

	// Calculate fade amount based on distance to mesh/texture edge
    float texture_fade = smoothstep(0.0, texture_fade_distance_x, texture_edge_distance_x) * smoothstep(0.0, texture_fade_distance_y, texture_edge_distance_y);
	float mesh_fade = smoothstep(0.0,mesh_fade_distance_x_start,UV.x) * smoothstep(0.0, mesh_fade_distance_x_end, 1.0-UV.x) *  smoothstep(0.0,mesh_fade_distance_y_start,UV.y) * smoothstep(0.0, mesh_fade_distance_y_end, 1.0-UV.y);

	ALPHA = tex.a * mesh_fade * texture_fade * alpha_factor;
}