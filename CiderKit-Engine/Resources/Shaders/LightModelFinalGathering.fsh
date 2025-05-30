float inverseLerp(float min, float max, float value) {
    return (value - min) / (max - min);
}

float luminance(vec3 color) {
    return color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
}

vec4 processLight(mat3 light, vec3 pos, vec3 normals) {
    if (light[2][1] == 0) {
        return vec4();
    }
    
    float lightPower = 0;

    if (light[2][2] == 0) {
        vec3 lightDirection = light[1];
        float dotProduct = dot(normals, lightDirection);
        if (dotProduct > 0) {
            lightPower = dotProduct;
        }
    }
    else {
        vec3 lightToPos = light[1] - pos;
        vec3 normalizedLightToPos = normalize(lightToPos);
        
        float dotProduct = dot(normals, normalizedLightToPos);
        if (dotProduct > 0) {
            float distanceToLight = length(lightToPos);
            vec3 lightFalloff = light[2];
            if (distanceToLight < lightFalloff[1]) {
                if (lightFalloff[2] < 0) {
                    lightPower = 1;
                }
                else {
                    lightPower = clamp(1.0 - inverseLerp(lightFalloff[0], lightFalloff[1], distanceToLight), 0.0, 1.0);
                    lightPower *= pow(dotProduct, lightFalloff[2]);
                }
            }
        }
    }

    return vec4(light[0] * lightPower, luminance(light[0]) * lightPower);
}

void main() {
    vec4 albedo = texture2D(u_albedo_texture, v_tex_coord);
    if (albedo.a > 0) {
        vec3 normals = texture2D(u_normals_texture, v_tex_coord).rgb;
 
        vec3 normalizedPos = texture2D(u_position_texture, v_tex_coord).rgb;
        vec3 pos = mix(u_position_ranges[0], u_position_ranges[1], normalizedPos);

        vec4 lights = processLight(u_light0, pos, normals)
            + processLight(u_light1, pos, normals)
            + processLight(u_light2, pos, normals)
            + processLight(u_light3, pos, normals)
            + processLight(u_light4, pos, normals)
            + processLight(u_light5, pos, normals)
            + processLight(u_light6, pos, normals)
            + processLight(u_light7, pos, normals)
            + processLight(u_light8, pos, normals)
            + processLight(u_light9, pos, normals)
            + processLight(u_light10, pos, normals)
            + processLight(u_light11, pos, normals)
            + processLight(u_light12, pos, normals)
            + processLight(u_light13, pos, normals)
            + processLight(u_light14, pos, normals)
            + processLight(u_light15, pos, normals);

        vec3 lightColor = mix(u_ambient_light, lights.rgb, lights[3]);
        gl_FragColor = vec4(lightColor * albedo.rgb * albedo.a, albedo.a);
    }
    else {
        gl_FragColor = SKDefaultShading();
    }
    
}
