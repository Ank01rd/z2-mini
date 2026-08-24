#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_time;
uniform float u_edge_glow;    // 边缘高光强度 (0.0 - 1.0)
uniform vec4 u_tint;          // 玻璃色调
uniform float u_radius;       // 圆角半径

out vec4 fragColor;

// 计算带圆角的 SDF (Signed Distance Field)
float roundedBoxSDF(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 uv = FlutterFragCoord().xy;
    vec2 center = u_size * 0.5;
    vec2 halfSize = u_size * 0.5;
    
    // 计算到边缘的距离 (用于菲涅尔效应)
    float dist = roundedBoxSDF(uv - center, halfSize, u_radius);
    
    // 边缘发光 (Fresnel) - 越靠近边缘越亮
    float edge = 1.0 - smoothstep(0.0, 15.0, -dist);
    edge = pow(edge, 2.5) * u_edge_glow;
    
    // 模拟色散 (Chromatic Aberration) - 边缘的彩虹光晕
    float aberration = edge * 0.15;
    vec3 chromatic = vec3(
        edge * 0.8 + aberration, 
        edge * 0.9, 
        edge * 1.0 + aberration
    );
    
    // 内部微弱的环境光遮蔽/渐变
    float innerShadow = smoothstep(0.0, 40.0, -dist) * 0.1;
    
    // 混合色调
    vec3 finalColor = chromatic + u_tint.rgb * u_tint.a * 0.5;
    finalColor += vec3(innerShadow);
    
    // 顶部微弱的高光反射
    float topHighlight = smoothstep(halfSize.y, halfSize.y - 40.0, uv.y) * 0.15;
    finalColor += vec3(topHighlight);
    
    // Alpha 通道：边缘更不透明，内部半透明
    float alpha = 0.1 + (edge * 0.6) + innerShadow;
    
    fragColor = vec4(finalColor, alpha);
}