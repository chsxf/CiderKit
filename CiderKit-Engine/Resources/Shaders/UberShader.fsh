vec2 nearestNeighbor(vec2 loc, vec2 size) {
    vec2 onePixel = vec2(1.0, 1.0) / size;
    vec2 coordinate = floor(loc * size) / size;
    return coordinate + onePixel / 2.0;
}

float inverseLerp(float min, float max, float value) {
    return (value - min) / (max - min);
}

vec3 inverseLerp(vec3 min, vec3 max, vec3 value) {
    return vec3(inverseLerp(min[0], max[0], value[0]), inverseLerp(min[1], max[1], value[1]), inverseLerp(min[2], max[2], value[2]));
}

vec4 shadeWithPosition(vec4 posTexColor, vec3 pos, mat3 posRanges) {
    vec3 adjustedPos = inverseLerp(posRanges[0], posRanges[1], pos + vec3(posTexColor.r, posTexColor.g, posTexColor.b * 0.25));
    return vec4(adjustedPos * posTexColor.a, posTexColor.a);
}

void main() {
    vec2 tc = nearestNeighbor(v_tex_coord, u_tex_size);
    
    if (u_shadeMode > 1.0) {
        gl_FragColor = texture2D(u_normals_texture, tc);
    }
    else if (u_shadeMode > 0.0) {
        vec4 texColor = texture2D(u_position_texture, tc);
        gl_FragColor = shadeWithPosition(texColor, a_position, u_position_ranges);
    }
    else {
        gl_FragColor = texture2D(u_texture, tc);
    }
}

