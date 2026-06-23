#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor1;
uniform vec4 uColor2;

// We will pass the normalized depth (Z) of the point to the shader,
// or we can just calculate a gradient based on the screen coordinate and time.
// Since drawRawPoints uses a single Paint, the shader applies to all points.
// We can color points by mapping the fragment coordinate.

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Create a dynamic gradient based on screen position and time
    // The blob will spin, so the UV coordinates will naturally cover the blob
    float mixValue = sin(uv.x * 3.1415 + uTime * 0.5) * 0.5 + 0.5;
    
    // Add some vertical variation
    mixValue += cos(uv.y * 3.1415 - uTime * 0.3) * 0.2;
    mixValue = clamp(mixValue, 0.0, 1.0);
    
    vec4 finalColor = mix(uColor1, uColor2, mixValue);
    
    fragColor = finalColor;
}
