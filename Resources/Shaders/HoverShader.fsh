void main() {
    int stripe = int(u_path_length) / 20;
    int h = int(v_path_distance) / stripe % 2;
    gl_FragColor = float4(h) * v_color_mix;
}
