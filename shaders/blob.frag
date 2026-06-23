/// Particle Blob Fragment Shader
///
/// Applies a dynamic, time-driven color gradient to all blob particles.
/// The gradient is based on normalized screen-space UV coordinates and the
/// elapsed time uniform, producing a smooth, perpetually shifting color field.
///
/// Uniform layout (flat float index via setFloat):
///   0-1  : uResolution (vec2)  — viewport size in pixels
///   2    : uTime       (float) — elapsed animation time
///   3-6  : uColor1     (vec4)  — primary RGBA color (normalized 0.0–1.0)
///   7-10 : uColor2     (vec4)  — secondary RGBA color (normalized 0.0–1.0)
///
/// Total: 11 floats.

#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// ── Uniforms ─────────────────────────────────────────────────────────────────
uniform vec2  uResolution;  // Viewport dimensions in pixels
uniform float uTime;        // Elapsed animation time in seconds
uniform vec4  uColor1;      // Primary color (RGBA, normalized)
uniform vec4  uColor2;      // Secondary color (RGBA, normalized)

out vec4 fragColor;

void main() {
    // Normalize fragment coordinate to [0.0, 1.0] UV space
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Horizontal wave: oscillates left-right based on time
    float wave1 = sin(uv.x * 3.14159 + uTime * 0.5) * 0.5 + 0.5;

    // Vertical ripple: slower oscillation on Y axis for depth variation
    float wave2 = cos(uv.y * 3.14159 - uTime * 0.3) * 0.2;

    // Diagonal shimmer: high-frequency diagonal wave for surface texture
    float shimmer = sin((uv.x + uv.y) * 6.28318 + uTime * 1.2) * 0.08;

    // Combine waves and clamp to valid blend range
    float mixValue = clamp(wave1 + wave2 + shimmer, 0.0, 1.0);

    // Interpolate between the two user-provided colors
    fragColor = mix(uColor1, uColor2, mixValue);
}
