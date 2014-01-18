// Fragment shader

varying lowp vec3 LightColor;

void main(void)
{
    /* Add diffuse and ambient light (constant) */
    gl_FragColor = vec4(LightColor, 1.0) + vec4(0.1);
}
