precision mediump float;
uniform vec2 uRes;
uniform float uT;
uniform vec3 uSurface;
uniform vec3 uPrimary;
uniform vec3 uTertiary;

float band(vec2 uv, float offset, float speed, float amp) {
   float y = sin(uv.x * 3.0 + uT * speed + offset) * amp
          + sin(uv.x * 7.0 - uT * speed * 0.6 + offset) * amp * 0.4
          + 0.5 + offset * 0.12;
          return smoothstep(0.10, 0.0, abs(uv.y - y));
}

void main() {
  vec2 uv = gl_FragCoord.xy / uRes;

  vec3 col = uSurface;
  col = mix(col, mix(uSurface, uTertiary, 0.6), band(uv, -0.8, 0.20, 0.06) * 0.6);
  col = mix(col, mix(uSurface, uPrimary,  0.5), band(uv,  0.0, 0.30, 0.08) * 0.7);
  col = mix(col, mix(uSurface, uPrimary,  0.9), band(uv,  0.7, 0.45, 0.05) * 0.5);

  gl_FragColor = vec4(col, 1.0);
}

