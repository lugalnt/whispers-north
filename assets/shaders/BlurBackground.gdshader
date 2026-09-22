shader_type canvas_item;

// Slider para ajustar la intensidad del blur en el Inspector
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec2 uv = UV;
    vec2 texture_pixel_size = TEXTURE_PIXEL_SIZE;
    
    vec4 blurred_color = vec4(0.0);
    float total_weight = 0.0;
    
    // 1. Aplicamos el efecto de Blur primero
    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            vec2 offset = vec2(x, y) * texture_pixel_size * blur_amount;
            float weight = exp(-0.5 * (x * x + y * y));
            
            blurred_color += texture(TEXTURE, uv + offset) * weight;
            total_weight += weight;
        }
    }
    
    // Obtenemos el color final difuminado
    vec4 final_color = blurred_color / total_weight;

    // 2. Tu código original: Definir el color del cielo
    vec3 sky_color = vec3(118.0 / 255.0, 185.0 / 255.0, 227.0 / 255.0);

    // 3. Hacemos transparente el azul sobre el resultado difuminado
    if (distance(final_color.rgb, sky_color) < 0.08) {
        final_color.a = 0.0;
    }

    // Asignamos el resultado a la pantalla
    COLOR = final_color;
}
