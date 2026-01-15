shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled;

uniform vec4 ring_color : source_color = vec4(0.3, 0.95, 1.0, 1.0);
uniform float radius_world = 3.0;
uniform float width_world  = 0.15;
uniform float edge_softness = 0.01;    // edge fade (smaller = crisper)
uniform float edge_sharpness = 5.0;    // controls overall crispness

// --- Dotted parameters ---
uniform bool dotted = false;
uniform float dot_length_deg = 10.0;
uniform float gap_length_deg = 10.0;
uniform float dot_roundness = 2.0;     // affects only ends of dot
uniform float dot_sharpness = 3.0;

// --- Rotation ---
uniform float rotation_speed_deg = 0.0;
uniform float angle_offset_deg = 0.0;

varying vec3 v_world_pos;
varying vec2 v_center_xz;

void vertex() {
    vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
    v_world_pos = wp.xyz;
    v_center_xz = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xz;
}

void fragment() {
    // --- base ring width ---
    float d = length(v_world_pos.xz - v_center_xz);
    float inner = radius_world - width_world * 0.5;
    float outer = radius_world + width_world * 0.5;

    // Harder, crisp edges radially
    float ring = smoothstep(inner - edge_softness, inner, d)
               * (1.0 - smoothstep(outer, outer + edge_softness, d));
    ring = pow(ring, edge_sharpness);

    // --- dotted shape only affects angular direction ---
    if (dotted) {
        float angle = degrees(atan(v_world_pos.z - v_center_xz.y,
                                   v_world_pos.x - v_center_xz.x));
        if (angle < 0.0) angle += 360.0;

        float animated_angle = mod(angle + angle_offset_deg + TIME * rotation_speed_deg, 360.0);
        float segment_len = dot_length_deg + gap_length_deg;
        float mod_angle = mod(animated_angle, segment_len);

        // Fade only at dot ends (angular direction)
        float fade_in  = smoothstep(0.0, dot_roundness, mod_angle);
        float fade_out = 1.0 - smoothstep(dot_length_deg - dot_roundness, dot_length_deg, mod_angle);
        float dot_mask = pow(fade_in * fade_out, dot_sharpness);

        ring *= dot_mask;
    }

    ALBEDO = ring_color.rgb;
    ALPHA  = ring * ring_color.a;
}
