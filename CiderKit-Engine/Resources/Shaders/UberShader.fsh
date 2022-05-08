vec2 nearestNeighbor(vec2 loc, vec2 size) {
    vec2 onePixel = vec2(1.0, 1.0) / size;
    vec2 coordinate = floor(loc * size) / size;
    return coordinate + onePixel / 2.0;
}

float inverseLerp(float min, float max, float value) {
    return (value - min) / (max - min);
}

vec4 shadeWithPosition(vec4 posTexColor, vec3 pos, vec4 xy_ranges, float z_range) {
    vec3 adjustedPos = vec3(0, 0, 0);
    adjustedPos.x = inverseLerp(xy_ranges[0], xy_ranges[1], pos.x + posTexColor.r);
    adjustedPos.y = inverseLerp(xy_ranges[2], xy_ranges[3], pos.y + posTexColor.g);
    adjustedPos.z = inverseLerp(0, z_range, pos.z + posTexColor.b * 0.25);
    adjustedPos *= posTexColor.a;
    return vec4(adjustedPos, posTexColor.a);
}

void main() {
    vec2 tc = nearestNeighbor(v_tex_coord, u_tex_size);
    
    if (u_shadeMode > 1.0) {
        gl_FragColor = texture2D(u_normals_texture, tc);
    }
    else if (u_shadeMode > 0.0) {
        vec4 texColor = texture2D(u_position_texture, tc);
        gl_FragColor = shadeWithPosition(texColor, a_position, u_position_xy_ranges, u_position_z_range);
    }
    else {
        gl_FragColor = texture2D(u_texture, tc);
    }
}

